use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :noodl, NoodlWeb.Endpoint,
  load_from_system_env: true,
  http: [port: 4000, compress: true],
  check_origin: [
    "//${APP_DOMAIN}"
  ],
  url: [host: "${APP_DOMAIN", scheme: "https", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :noodl, Noodl.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  ssl: true,
  pool_size: 20

config :noodl,
  recording_client: API.RecordingLocal

config :noodl, Noodl.Emails.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN"),
  username: System.get_env("MAILGUN_USERNAME"),
  hackney_opts: [
    recv_timeout: :timer.minutes(1)
  ]

config :waffle,
  storage: Waffle.Storage.S3,
  bucket: {:system, "AWS_S3_BUCKET"},
  asset_host: System.get_env("AWS_CLOUDFRONT_DISTRO")

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

config :noodl,
  agora_app_id: System.get_env("AGORA_APP_ID"),
  agora_certificate: System.get_env("AGORA_CERT")

config :noodl, :strategies,
  github: [
    client_id: System.get_env("GITHUB_CLIENT_ID"),
    client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
    strategy: Assent.Strategy.Github,
    redirect_uri: System.get_env("GITHUB_REDIRECT_URI")
  ],
  google: [
    client_id: System.get_env("GOOGLE_CLIENT_ID"),
    client_secret: System.get_env("GOOGLE_CLIENT_SECRET"),
    strategy: Assent.Strategy.Google,
    redirect_uri: System.get_env("GOOGLE_REDIRECT_URI")
  ],
  apple: [
    client_id: System.get_Env("APPLE_CLIENT_ID"),
    team_id: System.get_env("APPLE_TEAM_ID"),
    private_key_id: System.get_env("APPLE_PRIVATE_KEY_ID"),
    strategy: Assent.Strategy.Apple,
    redirect_uri: System.get_env("APPLE_REDIRECT_URI"),
    private_key: System.get_env("APPLE_PRIVATE_KEY")
  ]

config :logger,
  level: :warning

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :noodl, NoodlWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [
#         :inet6,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :noodl, NoodlWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :noodl, NoodlWeb.Endpoint, server: true
#
# Note you can't rely on `System.get_env/1` when using releases.
# See the releases documentation accordingly.

# Finally import the config/prod.secret.exs which should be versioned
# separately.
# import_config "prod.secret.exs"
