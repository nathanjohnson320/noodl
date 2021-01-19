import * as pulumi from '@pulumi/pulumi';
import * as aws from '@pulumi/aws';
import * as awsx from '@pulumi/awsx';

// https://github.com/pulumi/examples/blob/master/aws-ts-static-website/index.ts
const stackConfig = new pulumi.Config('noodl-website');
const stack = pulumi.getStack();

const config = {
  targetDomain: stackConfig.require('targetDomain'),
  awsAccessKeyId: stackConfig.require('S3_READ_ACCESS_KEY'),
  awsSecretAccessKey: stackConfig.require('S3_READ_ACCESS_SECRET'),
  secretKeyBase: stackConfig.require('SECRET_KEY_BASE'),
  mailgunApiKey: stackConfig.require('MAILGUN_API_KEY'),
  mailgunDomain: stackConfig.require('MAILGUN_DOMAIN'),
  agoraAppId: stackConfig.require('AGORA_APP_ID'),
  agoraCert: stackConfig.require('AGORA_CERT'),
  dbRootPass: stackConfig.require('DB_ROOT_PASS'),
};

const tenMinutes = 60 * 10;

// Split a domain name into its subdomain and parent domain names.
// e.g. "www.example.com" => "www", "example.com".
function getDomainAndSubdomain(
  domain: string
): { subdomain: string; parentDomain: string } {
  const parts = domain.split('.');
  if (parts.length < 2) {
    throw new Error(`No TLD found on ${domain}`);
  }
  // No subdomain, e.g. awesome-website.com.
  if (parts.length === 2) {
    return { subdomain: '', parentDomain: domain };
  }

  const subdomain = parts[0];
  parts.shift(); // Drop first element.
  return {
    subdomain,
    // Trailing "." to canonicalize domain.
    parentDomain: parts.join('.') + '.',
  };
}

const eastRegion = new aws.Provider('east', {
  profile: aws.config.profile,
  region: 'us-east-1', // Per AWS, ACM certificate must be in the us-east-1 region.
});

const certificate = new aws.acm.Certificate(
  'certificate',
  {
    domainName: config.targetDomain,
    validationMethod: 'DNS',
  },
  { provider: eastRegion }
);

const domainParts = getDomainAndSubdomain(config.targetDomain);
const hostedZoneId = aws.route53
  .getZone({ name: domainParts.parentDomain }, { async: true })
  .then((zone) => zone.zoneId);

/**
 *  Create a DNS record to prove that we _own_ the domain we're requesting a certificate for.
 *  See https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html for more info.
 */
const certificateValidationDomain = new aws.route53.Record(
  `${config.targetDomain}-validation`,
  {
    name: certificate.domainValidationOptions[0].resourceRecordName,
    zoneId: hostedZoneId,
    type: certificate.domainValidationOptions[0].resourceRecordType,
    records: [certificate.domainValidationOptions[0].resourceRecordValue],
    ttl: tenMinutes,
  }
);

/**
 * This is a _special_ resource that waits for ACM to complete validation via the DNS record
 * checking for a status of "ISSUED" on the certificate itself. No actual resources are
 * created (or updated or deleted).
 *
 * See https://www.terraform.io/docs/providers/aws/r/acm_certificate_validation.html for slightly more detail
 * and https://github.com/terraform-providers/terraform-provider-aws/blob/master/aws/resource_aws_acm_certificate_validation.go
 * for the actual implementation.
 */
const certificateValidation = new aws.acm.CertificateValidation(
  'certificateValidation',
  {
    certificateArn: certificate.arn,
    validationRecordFqdns: [certificateValidationDomain.fqdn],
  },
  { provider: eastRegion }
);

const bucket = new aws.s3.Bucket('noodl-cdn', {
  corsRules: [
    {
      allowedHeaders: ['*'],
      allowedOrigins: ['*'],
      allowedMethods: ['GET'],
    },
  ],
});
const cloudfrontAccessIdentity = new aws.cloudfront.OriginAccessIdentity(
  'noodl-tv-access',
  {
    comment: 'To grant access to the private bucket',
  }
);

const distro = new aws.cloudfront.Distribution('noodl-tv', {
  origins: [
    {
      domainName: bucket.bucketDomainName,
      originId: 'noodl-tv',
      s3OriginConfig: {
        originAccessIdentity:
          cloudfrontAccessIdentity.cloudfrontAccessIdentityPath,
      },
    },
  ],
  enabled: true,
  defaultRootObject: 'index.html',
  defaultCacheBehavior: {
    allowedMethods: ['GET', 'HEAD', 'OPTIONS'],
    cachedMethods: ['GET', 'HEAD', 'OPTIONS'],
    targetOriginId: 'noodl-tv',
    forwardedValues: {
      headers: ['Origin'],
      queryString: true,
      cookies: {
        forward: 'none',
      },
    },
    viewerProtocolPolicy: 'https-only',
    minTtl: 31536000,
    defaultTtl: 31536000,
    maxTtl: 31536000,
  },
  priceClass: 'PriceClass_100',
  restrictions: {
    geoRestriction: {
      restrictionType: 'blacklist',
      locations: ['CN', 'RO', 'RU', 'IR', 'IQ', 'KP', 'SY'],
    },
  },
  viewerCertificate: {
    cloudfrontDefaultCertificate: true,
  },
});

const s3Policy = pulumi
  .all([cloudfrontAccessIdentity.iamArn, bucket.arn])
  .apply(([identityIamArn, bucketArn]) =>
    aws.iam.getPolicyDocument({
      statements: [
        {
          actions: ['s3:GetObject'],
          principals: [
            {
              identifiers: [identityIamArn],
              type: 'AWS',
            },
          ],
          resources: [`${bucketArn}/*`],
        },
        {
          actions: ['s3:ListBucket'],
          principals: [
            {
              identifiers: [identityIamArn],
              type: 'AWS',
            },
          ],
          resources: [bucketArn],
        },
      ],
    })
  );
new aws.s3.BucketPolicy('cloudfront-bucket-policy', {
  bucket: bucket.id,
  policy: s3Policy.apply((s3Policy) => s3Policy.json),
});

const cluster = new awsx.ecs.Cluster('web-app');

const dbSg = new aws.ec2.SecurityGroup('allow_postgres', {
  description: 'Allow inbound RDS connection requests',
  vpcId: cluster.vpc.id,
  ingress: [
    {
      fromPort: 5432,
      toPort: 5432,
      protocol: 'tcp',
      cidrBlocks: ['0.0.0.0/0'],
    },
  ],
  egress: [
    {
      fromPort: 0,
      toPort: 0,
      protocol: 'tcp',
      cidrBlocks: ['0.0.0.0/0'],
    },
  ],
  tags: {
    Name: 'noodl Db Subnet',
    App: 'noodl',
  },
});

const dbSubnet = new aws.rds.SubnetGroup('noodl', {
  subnetIds: cluster.vpc.publicSubnetIds,
  tags: {
    Name: 'noodl DB Subnet',
    App: 'noodl',
  },
});

const db = new aws.rds.Instance('noodl', {
  allocatedStorage: 20,
  storageType: 'gp2',
  engine: 'postgres',
  engineVersion: '12.4',
  instanceClass: 'db.t2.micro',
  password: config.dbRootPass,
  username: 'root',
  tags: {
    App: 'noodl',
  },
  vpcSecurityGroupIds: [dbSg.id],
  maintenanceWindow: 'Mon:00:00-Mon:03:00',
  backupWindow: '04:00-07:00',
  backupRetentionPeriod: 1,
  deletionProtection: false,
  finalSnapshotIdentifier: `noodl-${stack}`,
  dbSubnetGroupName: dbSubnet.name,
  publiclyAccessible: true,
});

const alb = new awsx.elasticloadbalancingv2.ApplicationLoadBalancer(
  'web-app-lb',
  {
    external: true,
    securityGroups: cluster.securityGroups,
    idleTimeout: 4000,
  }
);
const http = alb.createListener('web-app-ssl-redirect', {
  external: true,
  protocol: 'HTTP',
  port: 80,
  defaultActions: [
    {
      type: 'redirect',
      redirect: {
        port: '443',
        protocol: 'HTTPS',
        statusCode: 'HTTP_301',
      },
    },
  ],
});
const ssl = alb.createListener('web-app-ssl', {
  external: true,
  protocol: 'HTTPS',
  port: 443,
  certificateArn: certificate.arn,
  targetGroup: {
    port: 4000,
    protocol: 'HTTP',
    healthCheck: {
      path: '/',
      port: '4000',
      protocol: 'HTTP',
      matcher: '200-399',
    },
  },
});

const img = awsx.ecs.Image.fromDockerBuild('noodl-container', {
  context: './app',
  dockerfile: './app/Dockerfile',
  env: {},
  args: {
    databaseUrl: pulumi.interpolate`postgres://${db.username}:${db.password}@${db.endpoint}/noodl_repo`,
    awsS3Bucket: bucket.bucket || '',
    awsCloudfrontDistro: pulumi.interpolate `https://${distro.domainName}`,
    awsAccessKeyId: config.awsAccessKeyId,
    awsSecretAccessKey: config.awsSecretAccessKey,
    secretKeyBase: config.secretKeyBase,
    mailgunApiKey: config.mailgunApiKey,
    mailgunDomain: config.mailgunDomain,
    agoraAppId: config.agoraAppId,
    agoraCert: config.agoraCert,
  },
});

// Step 4: Create a Fargate service task that can scale out.
const app = new awsx.ecs.FargateService('app-svc', {
  cluster,
  taskDefinitionArgs: {
    container: {
      environment: [
          { name: 'MIX_ENV', value: stack },
          { name: 'MAILGUN_DOMAIN', value: config.mailgunDomain },
          { name: 'MAILGUN_API_KEY', value: config.mailgunApiKey },
          { name: 'AGORA_APP_ID', value: config.agoraAppId },
          { name: 'AGORA_CERT', value: config.agoraCert },
      ],
      image: img,
      memory: 512 /* MB */,
      portMappings: [ssl],
    },
  },
  desiredCount: 1,
});

// Creates a new Route53 DNS record pointing the domain to the CloudFront distribution.
function createAliasRecord(
  targetDomain: string,
  alb: awsx.elasticloadbalancingv2.LoadBalancer
): aws.route53.Record {
  const domainParts = getDomainAndSubdomain(targetDomain);
  const hostedZoneId = aws.route53
    .getZone({ name: domainParts.parentDomain }, { async: true })
    .then((zone) => zone.zoneId);
  return new aws.route53.Record(targetDomain, {
    name: domainParts.subdomain,
    zoneId: hostedZoneId,
    type: 'A',
    aliases: [
      {
        name: alb.loadBalancer.dnsName,
        zoneId: alb.loadBalancer.zoneId,
        evaluateTargetHealth: true,
      },
    ],
  });
}

const aRecord = createAliasRecord(config.targetDomain, alb);

export const httpEndpoint = http.endpoint.hostname;
export const sslEndpoint = ssl.endpoint.hostname;
export const certificateValidationArn = certificateValidation.certificateArn;
export const dbUrl = db.endpoint;
export const domainRecords = aRecord.records;
export const distroUrl = distro.domainName;
