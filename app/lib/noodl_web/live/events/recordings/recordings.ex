defmodule NoodlWeb.Live.Events.Recordings do
  @moduledoc ~S"""
  LiveView for the recordings show page.
  """
  use NoodlWeb, :live_view

  alias Noodl.Events

  def mount(%{"id" => slug}, session, socket) do
    event = Events.get_event_by!(slug: slug)
    recordings = Events.list_recordings_for_event(event, [:session])

    {:ok,
     socket
     |> Authentication.assign_user(session)
     |> assign(
       recordings: recordings,
       event: event,
       search: ""
     )}
  end

  def handle_event("filter", %{"search" => %{"name" => name}}, socket) do
    {:noreply, socket |> assign(search: name)}
  end

  def filter_recordings(recordings, ""), do: recordings

  def filter_recordings(recordings, search) do
    Enum.filter(recordings, fn recording ->
      String.contains?(String.downcase(recording.session.name), String.downcase(search))
    end)
  end
end
