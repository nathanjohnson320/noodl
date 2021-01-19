defmodule NoodlWeb.Live.Events.Session.Dashboard.Viewer do
  use NoodlWeb, :live_view

  alias Agora.AccessKey, as: Agora
  alias Noodl.{Events, Messages}
  alias Noodl.Events.Event.Session
  alias NoodlWeb.{Presence, EventsView}
  alias NoodlWeb.Router.Helpers, as: Routes

  @app_id Application.get_env(:noodl, :agora_app_id, "")
  @certificate Application.get_env(:noodl, :agora_certificate, "")

  def mount(
        _params,
        %{
          "user" => nil,
          "session" => session,
          "role" => :spectator,
          "user_timezone" => user_timezone
        },
        socket
      ) do
    %{channel: channel_name, message: message} = Events.stream_channel_details(session)
    event = Events.get_event_by!(id: session.event_id)

    pid = Session.initialize(session)

    user = Events.generate_anonymous_user()

    Presence.track(
      self(),
      channel_name,
      user.id,
      user
    )

    # Preload the session state
    %{
      time_elapsed: time_elapsed,
      presenters: presenters
    } = Session.mounted(pid, session)

    future_sessions = Events.active_sessions_for_event(session.event)

    agora_token = Agora.new_token(@app_id, @certificate, channel_name, "0", [:join_channel])

    {:ok,
     socket
     |> assign(
       agora_token: agora_token,
       app_id: @app_id,
       channel_name: channel_name,
       event: event,
       future_sessions: future_sessions,
       message: message,
       pid: pid,
       presenters: presenters,
       role: :audience,
       session: session,
       time_elapsed: time_elapsed,
       user: user,
       user_timezone: user_timezone,
       viewer_count: "Loading...",
       viewers: []
     ), temporary_assigns: [messages: []]}
  end

  def mount(
        _params,
        %{"user" => user, "session" => session, "user_timezone" => user_timezone, "role" => role},
        socket
      ) do
    %{channel: channel_name, message: message} = Events.stream_channel_details(session, user)

    pid = Session.initialize(session)

    Presence.track(
      self(),
      channel_name,
      user.id,
      %{
        email: user.email,
        firstname: user.firstname,
        lastname: user.lastname,
        id: user.id,
        role: role
      }
    )

    # Preload the session state
    %{
      time_elapsed: time_elapsed
    } = Session.mounted(pid, session)

    future_sessions = Events.active_sessions_for_event(session.event)

    agora_token_primary =
      Agora.new_token(@app_id, @certificate, channel_name, "#{user.recording_id}", [
        :join_channel
      ])

    {:ok,
     socket
     |> assign(
       agora_token_primary: agora_token_primary,
       app_id: @app_id,
       channel_name: channel_name,
       message: message,
       pid: pid,
       presenters: [],
       role: role,
       session: session,
       time_elapsed: time_elapsed,
       user: user,
       user_timezone: user_timezone,
       viewer_count: "Loading...",
       viewers: [],
       future_sessions: future_sessions
     ), temporary_assigns: [messages: Messages.list_messages_for_session(session.id)]}
  end

  def handle_info(
        %{event: "kick_user", payload: %{id: kicked_user}},
        %{assigns: %{user: %{id: id}, session: session}} = socket
      )
      when id == kicked_user do
    {:noreply,
     socket
     |> put_flash(
       :error,
       "You've been banned from chat by an organizer."
     )
     |> push_redirect(
       to:
         Routes.events_session_dashboard_path(
           socket,
           :dashboard,
           session.event.slug,
           session.slug
         )
     )}
  end

  def handle_info(
        %{event: "unban_user", payload: %{id: kicked_user}},
        %{assigns: %{user: %{id: id}, session: session}} = socket
      )
      when id == kicked_user do
    {:noreply,
     socket
     |> put_flash(
       :info,
       "You've been unbanned by an event organizer."
     )
     |> push_redirect(
       to:
         Routes.events_session_dashboard_path(
           socket,
           :dashboard,
           session.event.slug,
           session.slug
         )
     )}
  end

  def handle_info(%{event: "unban_user"}, socket) do
    {:noreply, socket}
  end

  def handle_info(
        %{event: "presence_diff", payload: _payload},
        %{assigns: %{channel_name: channel_name}} = socket
      ) do
    viewers = channel_name |> Presence.get_users()

    {:noreply, assign(socket, viewers: viewers, viewer_count: Enum.count(viewers))}
  end

  def handle_info(
        %{
          event: "status",
          payload: %{status: "ended", session: session}
        },
        socket
      ) do
    future_sessions = Events.active_sessions_for_event(session.event)
    {:noreply, assign(socket, session: session, future_sessions: future_sessions)}
  end

  def handle_info(
        %{
          event: "status",
          payload: %{
            activity: activity,
            session: session,
            time_elapsed: time_elapsed
          }
        },
        socket
      ) do
    {:noreply,
     assign(socket,
       session: session,
       activities: [activity],
       session: session,
       time_elapsed: time_elapsed
     )}
  end

  defdelegate handle_info(
                params,
                socket
              ),
              to: NoodlWeb.Live.Messaging.Chat

  def timer(time) do
    Timex.format!(time, "%T", :strftime)
  end

  defdelegate cover_photo_url(exp), to: EventsView
end
