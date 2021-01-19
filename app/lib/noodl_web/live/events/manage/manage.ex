defmodule NoodlWeb.Live.Events.Manage do
  @moduledoc ~S"""
  LiveView for the manage event page.
  """
  use NoodlWeb, :live_view
  use Timex

  alias Noodl.Accounts
  alias Noodl.Events
  alias NoodlWeb.EventsView

  @default_view "overview"
  @status_ended "ended"

  def mount(%{"id" => id} = params, session, socket) do
    event =
      Events.get_event_by!(%{slug: id}, [
        :releases,
        :sessions
      ])

    speakers = Accounts.list_event_members_with_roles([:speaker], event)
    organizers = Accounts.list_event_members_with_roles([:organizer], event)
    sessions = Events.get_sessions_by_event(event.id)

    {:ok,
     socket
     |> Authentication.assign_user(session)
     |> assign(
       overview_steps: [
         {"Add Organizers and Speakers", not Enum.empty?(organizers) or not Enum.empty?(speakers),
          Routes.live_path(socket, __MODULE__, event.slug, :members)},
         {"Create Tickets", not Enum.empty?(event.releases),
          Routes.live_path(socket, __MODULE__, event.slug, :tickets)},
         {"Create a session", not Enum.empty?(event.sessions),
          Routes.live_path(socket, __MODULE__, event.slug, :schedule)},
         {"Upload event splash image", not is_nil(event.cover_photo),
          Routes.live_path(socket, __MODULE__, event.slug, :details)}
       ],
       current_tab: params["view"] || @default_view,
       event: event,
       sessions: sessions
     )}
  end

  def handle_event(
        "change_status",
        %{"status" => status},
        %{assigns: %{event: event}} = socket
      )
      when status in ["live", "draft"] do
    live = status == "live"
    {:ok, _event} = Events.update_event(event, %{"is_live" => live})

    {:noreply,
     socket
     |> push_redirect(to: Routes.live_path(socket, __MODULE__, event.slug))}
  end

  def handle_event(
        "proceed",
        _params,
        %{assigns: %{event: event, sessions: sessions}} = socket
      ) do
    now = NaiveDateTime.utc_now()

    active_session =
      Enum.find(sessions, fn s ->
        Timex.after?(now, s.start_datetime) and Timex.before?(now, s.end_datetime) and
          s.status != @status_ended
      end)

    if active_session do
      {:noreply,
       socket
       |> push_redirect(
         to:
           Routes.events_session_dashboard_path(
             socket,
             :dashboard,
             event.slug,
             active_session.slug
           )
       )}
    else
      {:ok, first_session} = Enum.fetch(sessions, 0)

      {:noreply,
       socket
       |> push_redirect(
         to:
           Routes.events_session_dashboard_path(
             socket,
             :dashboard,
             event.slug,
             first_session.slug
           )
       )}
    end
  end

  def expired?(%{end_datetime: end_datetime}) do
    now = NaiveDateTime.utc_now()

    Timex.after?(now, end_datetime)
  end

  defdelegate pretty_manage_date(a, b), to: EventsView
  defdelegate event_setup?(a), to: EventsView
end
