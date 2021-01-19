defmodule(Noodl.MixProject) do
  use(Mix.Project)

  def(project) do
    [
      app: :noodl,
      version: "1.4.2",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def(application) do
    [mod: {Noodl.Application, []}, extra_applications: [:logger, :runtime_tools, :crypto]]
  end

  defp(elixirc_paths(:test)) do
    ["lib", "test/support"]
  end

  defp(elixirc_paths(_)) do
    ["lib"]
  end

  defp(deps) do
    [
      {:agora, "~> 1.0.0"},
      {:argon2_elixir, "~> 2.0"},
      {:assent, "~> 0.1.13"},
      {:bamboo, "~> 1.4"},
      {:credo, "~> 1.2", [only: [:dev, :test], runtime: false]},
      {:ecto_autoslug_field, "~> 2.0"},
      {:ecto, "~> 3.4.3", [override: true]},
      {:ecto_sql, "~> 3.1"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:earmark, "~> 1.4.7"},
      {:ex_machina, "~> 2.3", [only: :test]},
      {:floki, ">= 0.0.0", [only: :test]},
      {:gettext, "~> 0.11"},
      {:hackney, "~> 1.9"},
      {:httpoison, "~> 1.6"},
      {:icalendar, "~> 1.0.2", []},
      {:jason, "~> 1.2", [override: true]},
      {:mint, "~> 1.0", override: true},
      {:mixxer, "~> 1.0.3", [only: :dev]},
      {:mojito, "~> 0.7.3"},
      {:money, "~> 1.4"},
      {:mox, "~> 0.5"},
      {:navigation_history, "~> 0.3"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", [only: :dev]},
      {:phoenix_live_view, "~> 0.15"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.2"},
      {:porcelain, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:quantum, "~> 3.0"},
      {:stripity_stripe, "~> 2.8.0"},
      {:sweet_xml, "~> 0.6"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:timex, "~> 3.5"},
      {:ua_parser, "~> 1.8"},
      {:waffle, "~> 1.1.1"},
      {:waffle_ecto, "~> 0.0.9"},
      {:web_push_encryption, "~> 0.3"}
    ]
  end

  defp(aliases) do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
