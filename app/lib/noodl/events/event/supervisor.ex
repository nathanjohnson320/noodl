defmodule Noodl.Events.Event.Supervisor do
  use DynamicSupervisor

  @moduledoc ~S"""
  A supervisor for all the event sessions so we
  can dynamically spin them up.
  """

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(deploy_module, initial_state) do
    spec = {deploy_module, initial_state}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end
end
