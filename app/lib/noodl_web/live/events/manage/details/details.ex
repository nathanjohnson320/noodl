defmodule NoodlWeb.Live.Events.Details do
  @moduledoc ~S"""
  LiveView for the manage event details page.
  """
  use NoodlWeb, :live_view

  alias NoodlWeb.EventsView
  alias Noodl.{Events, Image}
  alias Noodl.Events.Event

  def mount(_params, %{"event" => event, "user" => user}, socket) do
    event = Events.get_event_by!(slug: event)

    {:ok,
     socket
     |> assign(
       user: user,
       editing: false,
       validating: false,
       event: event
     )
     |> allow_upload(:cover_photo, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  def handle_event("cancel", _, %{assigns: %{event: event}} = socket) do
    {:noreply, socket |> assign(editing: false, changeset: Events.change_event(event))}
  end

  def handle_event("edit", _, %{assigns: %{event: event}} = socket) do
    {:noreply,
     socket
     |> assign(editing: true, changeset: Events.change_event(event))}
  end

  def handle_event(
        "validate",
        %{"event" => event_params},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    event = Ecto.Changeset.apply_changes(changeset)
    changeset = Event.changeset(event, event_params)

    {:noreply, assign(socket, validating: true, changeset: changeset)}
  end

  def handle_event(
        "submit",
        %{"event" => event_params},
        %{assigns: %{event: event}} = socket
      ) do
    case Events.update_event(event, event_params, fn event ->
           consume_uploaded_entries(socket, :cover_photo, fn %{path: path}, entry ->
             Events.update_cover_photo(event, path, entry)
           end)
           |> Image.all_ok?(event)
         end) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> put_flash(:info, "Event saved successfully.")
         |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :details))}

      {:error, changeset} ->
        {:noreply, assign(socket, validating: true, changeset: changeset)}

      {:error, _, message, _} ->
        {:noreply, socket |> put_flash(:info, message)}
    end
  end

  def handle_event("remove_image", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:cover_photo, ref)}
  end

  defdelegate pretty_manage_date(a, b), to: EventsView
  defdelegate cover_photo_url(a), to: EventsView
  defdelegate timezones(), to: EventsView
  defdelegate languages(), to: EventsView
end
