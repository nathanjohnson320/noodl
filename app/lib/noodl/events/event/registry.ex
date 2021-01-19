defmodule Noodl.Events.Event.Registry do
  @moduledoc ~S"""
  Registry that contains state on in progress sessions
  """

  alias Noodl.Events.Session

  def register(%Session{} = session) do
    Registry.register(EventRegistry, session.id, session)
  end

  def lookup(%Session{} = session) do
    case Registry.lookup(EventRegistry, session.id) do
      [] -> {:error, :not_registered}
      [session] -> {:ok, session}
    end
  end
end
