defmodule NoodlWeb.Live.Events.Manage.Settings do
  @moduledoc ~S"""
  LiveView for the event settings.
  """
  use NoodlWeb, :live_view

  alias Noodl.Events

  def mount(_params, %{"event" => event, "user" => user}, socket) do
    event = Events.get_event_by!(slug: event)

    {:ok,
     assign(socket,
       user: user,
       event: event,
       validations: Events.validate_event(event)
     )}
  end

  def handle_event("unpublish", _, %{assigns: %{event: event}} = socket) do
    {:ok, _event} = Events.update_event(event, %{"is_live" => false})

    {:noreply,
     socket
     |> push_redirect(
       to: Routes.live_path(socket, Live.Events.Manage, event.slug, "settings")
     )}
  end

  def handle_event("publish", _, %{assigns: %{event: event}} = socket) do
    # If this fails it's not something the user can fix.
    {:ok, _tx} = Events.publish_event(event)

    {:noreply,
     socket
     |> push_redirect(
       to: Routes.live_path(socket, Live.Events.Manage, event.slug, "settings")
     )}
  end
end
