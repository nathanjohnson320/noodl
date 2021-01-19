defmodule Noodl.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Noodl.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Noodl.PubSub},
      Noodl.Telemetry,
      # Start the endpoint when the application starts
      NoodlWeb.Endpoint,
      Noodl.Scheduler,
      NoodlWeb.Presence,
      {Registry, keys: :unique, name: EventRegistry},
      {Noodl.Events.Event.Supervisor, name: EventSupervisor},
      {Noodl.Events.Transcoder, []},
      {Noodl.Ticketing.Cart, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Noodl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NoodlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
