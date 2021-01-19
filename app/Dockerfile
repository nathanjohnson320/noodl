FROM elixir:1.10-alpine

RUN apk add --update nodejs nodejs-npm ffmpeg build-base imagemagick

# Static ENV Vars
ENV MIX_ENV prod
ENV APP_NAME noodl
ENV PORT 4000

# Build Time Vars
ARG secretKeyBase
ENV SECRET_KEY_BASE=${secretKeyBase}

ARG databaseUrl
ENV DATABASE_URL=${databaseUrl}

ARG mailgunApiKey
ENV MAILGUN_API_KEY=${mailgunApiKey}}
ARG mailgunDomain
ENV MAILGUN_DOMAIN=${mailgunDomain}

ARG agoraAppId
ENV AGORA_APP_ID=${agoraAppId}
ARG agoraCert
ENV AGORA_CERT=${agoraCert}

ARG awsS3Bucket
ENV AWS_S3_BUCKET=${awsS3Bucket}
ARG awsCloudfrontDistro
ENV AWS_CLOUDFRONT_DISTRO=${awsCloudfrontDistro}
ARG awsAccessKeyId
ENV AWS_ACCESS_KEY_ID=${awsAccessKeyId}
ARG awsSecretAccessKey
ENV AWS_SECRET_ACCESS_KEY=${awsSecretAccessKey}

# Create app directory and copy the Elixir projects into it
RUN mkdir /$APP_NAME
COPY . /$APP_NAME
WORKDIR /$APP_NAME

# Build/Install the app
RUN ./build.sh

EXPOSE $PORT

CMD ["mix", "phx.server"]
