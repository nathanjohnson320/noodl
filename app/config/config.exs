# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :noodl,
  ecto_repos: [Noodl.Repo]

# Configures the endpoint
config :noodl, NoodlWeb.Endpoint,
  url: [host: "localhost"],
  live_view: [
    signing_salt: "wGBoV6IOATh7BkK2w29gQVJBq4494W4V"
  ],
  secret_key_base: "998RiabwljIJ2XLm8xpD1ZtwjMaLK2cOnQwNnjYWogL2NyFtlr4AxlrIQBju65/O",
  render_errors: [view: NoodlWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Noodl.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET")

config :money,
  default_currency: :USD

config :noodl, Noodl.Scheduler,
  jobs: [
    {"@daily", {Noodl.Ticketing, :payout, []}},
    {"@weekly", {Noodl.Events, :weekly_summary, []}},
    {"*/5 * * * *", {Noodl.Notifications.Push, :events_starting, [5]}}
  ]

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :ex_aws,
  json_codec: Jason

config :ex_aws, :hackney_opts,
  follow_redirect: true,
  recv_timeout: :timer.minutes(15)

config :noodl, FeatureFlags, enabled: [:direct_messaging, :feedback_modal]

config :web_push_encryption, :vapid_details,
  subject: "mailto:hello@noodl.tv",
  public_key:
    System.get_env("VAPID_PUBLIC_KEY"),
  private_key: System.get_env("VAPID_PRIVATE_KEY")

config :porcelain, driver: Porcelain.Driver.Basic

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
