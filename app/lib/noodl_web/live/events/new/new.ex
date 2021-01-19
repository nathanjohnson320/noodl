defmodule NoodlWeb.Live.Events.New do
  @moduledoc ~S"""
  LiveView for the new event page.
  """
  use NoodlWeb, :live_view

  alias NoodlWeb.EventsView
  alias Noodl.{Events, Image}
  alias Noodl.Events.Event

  def mount(_params, session, socket) do
    %{assigns: %{user: user}} = Authentication.assign_user(socket, session)

    event = %Event{
      creator_id: user.id,
      start_datetime: start_datetime(),
      end_datetime: end_datetime()
    }

    {:ok,
     socket
     |> assign(
       user: user,
       server_error: "",
       validating: false,
       event: event,
       categories: EventsView.topics(),
       changeset: Event.changeset(event)
     )
     |> allow_upload(:cover_photo, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  def handle_event(
        "validate",
        %{"event" => params},
        %{assigns: %{event: event}} = socket
      ) do
    {:noreply,
     assign(socket,
       validating: true,
       changeset: Event.changeset(event, params)
     )}
  end

  def handle_event(
        "submit",
        %{"event" => event_params},
        %{
          assigns: %{
            event: event
          }
        } = socket
      ) do
    case Events.create_event(
           event,
           event_params,
           fn %{event: event} ->
             consume_uploaded_entries(socket, :cover_photo, fn %{path: path}, entry ->
               Events.update_cover_photo(event, path, entry)
             end)
             |> Image.all_ok?(event)
           end
         ) do
      {:ok, event} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Event successfully created! We just need a few more pieces of information before you make it live!"
         )
         |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug))}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           validating: true,
           changeset: changeset
         )}

      _error ->
        {:noreply,
         assign(socket,
           validating: true,
           changeset: Event.changeset(event, event_params)
         )}
    end
  end

  def handle_event("remove_image", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:cover_photo, ref)}
  end

  def end_datetime() do
    Timex.shift(Timex.now(), days: 3)
    |> NaiveDateTime.truncate(:second)
  end

  def start_datetime() do
    Timex.now()
    |> Timex.shift(minutes: 15)
    |> NaiveDateTime.truncate(:second)
  end

  defdelegate timezones(), to: EventsView
  defdelegate languages(), to: EventsView
  defdelegate cover_photo_url(event), to: EventsView
end
