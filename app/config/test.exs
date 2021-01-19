use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :noodl, NoodlWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :noodl, Noodl.Repo,
  username: System.get_env("DB_USER") || "postgres",
  password: "postgres",
  database: "noodl_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :noodl,
  recording_client: RecordingApiClientBehaviourMock

config :noodl, Noodl.Emails.Mailer, adapter: Bamboo.TestAdapter, username: "no-reply@noodl.tv"

config :waffle,
  storage: Waffle.Storage.Local

config :noodl, :strategies,
  github: [
    strategy: TestProvider
  ],
  google: [strategy: TestProvider],
  apple: [strategy: TestProvider]
