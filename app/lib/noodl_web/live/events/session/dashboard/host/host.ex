defmodule NoodlWeb.Live.Events.Session.Dashboard.Host do
  use NoodlWeb, :live_view

  alias Agora.AccessKey, as: Agora
  alias Noodl.{Events, Messages}
  alias Noodl.Events.Event.Session
  alias NoodlWeb.{Presence, SessionView}

  @app_id Application.get_env(:noodl, :agora_app_id, "")
  @certificate Application.get_env(:noodl, :agora_certificate, "")

  def mount(
        _params,
        %{
          "user" => user,
          "session" => session,
          "capability" => capability,
          "user_timezone" => user_timezone,
          "role" => role
        },
        socket
      ) do
    session_not_started = NaiveDateTime.utc_now() |> Timex.before?(session.start_datetime)
    activities = Events.list_session_activities(session)

    %{channel: channel_name, message: message} = Events.stream_channel_details(session, user)
    future_sessions = Events.active_sessions_for_event(session.event)

    pid = Session.initialize(session)

    # This view suppports a larger background window (primary) and a smaller right hand one (secondary)
    # the hardcoded 1 and 2 for uid are because agora requires integers for recording but have no means
    # of specifying any labels on the channel otherwise so we can't tell what is primary or secondary
    # unless we know what the integer UIDs are.
    agora_primary_token =
      Agora.new_token(@app_id, @certificate, channel_name, "1", [
        :join_channel,
        :publish_audio,
        :publish_video,
        :request_publish_audio,
        :request_publish_video
      ])

    agora_secondary_token =
      Agora.new_token(@app_id, @certificate, channel_name, "2", [
        :join_channel,
        :publish_audio,
        :publish_video
      ])

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
      time_elapsed: time_elapsed,
      time_left: time_left
    } = Session.mounted(pid, session)

    {:ok,
     socket
     |> assign(
       agora_primary_token: agora_primary_token,
       agora_secondary_token: agora_secondary_token,
       app_id: @app_id,
       capability: capability,
       channel_name: channel_name,
       future_sessions: future_sessions,
       message: message,
       pid: pid,
       presenters: [],
       role: role,
       session: session,
       session_not_started: session_not_started,
       status_changing: false,
       time_elapsed: time_elapsed,
       time_left: time_left,
       user: user,
       user_timezone: user_timezone,
       viewer_count: "Loading...",
       viewers: []
     ),
     temporary_assigns: [
       messages: Messages.list_messages_for_session(session.id),
       activities: activities
     ]}
  end

  def handle_event("ready", _params, %{assigns: %{pid: pid}} = socket) do
    :ok = Session.ready(pid)

    {:noreply, socket |> assign(status_changing: true)}
  end

  def handle_event(
        "connected",
        _params,
        %{assigns: %{pid: pid}} = socket
      ) do
    :ok = Session.connected(pid)

    {:noreply, socket |> assign(status_changing: true)}
  end

  def handle_event("end_session", _params, %{assigns: %{pid: pid}} = socket) do
    Session.ended(pid)

    {:noreply, socket |> assign(status_changing: true)}
  end

  def handle_info(
        %{
          event: "status",
          payload: %{status: "ended", activity: activity, session: session}
        },
        socket
      ) do
    future_sessions = Events.active_sessions_for_event(session.event)

    {:noreply,
     assign(socket,
       status_changing: false,
       activities: [activity],
       session: session,
       future_sessions: future_sessions
     )}
  end

  def handle_info(
        %{event: "presence_diff", payload: _payload},
        %{
          assigns: %{
            channel_name: channel_name
          }
        } = socket
      ) do
    viewers = channel_name |> Presence.get_users()
    viewer_count = viewers |> Enum.count()

    {:noreply,
     assign(socket,
       viewers: viewers,
       viewer_count: viewer_count
     )}
  end

  def handle_info(
        %{
          event: "status",
          payload: %{
            session: session,
            activity: activity,
            time_elapsed: time_elapsed
          }
        },
        socket
      ) do
    {:noreply,
     assign(socket,
       status_changing: false,
       session: session,
       time_elapsed: time_elapsed,
       activities: [activity]
     )}
  end

  def handle_info(
        %{event: "kick_user", payload: %{activity: activity, id: kicked_user}},
        %{assigns: %{user: %{id: id}}} = socket
      )
      when id != kicked_user do
    {:noreply, assign(socket, activities: [activity])}
  end

  def handle_info(
        %{event: "unban_user", payload: %{activity: activity, id: kicked_user}},
        %{assigns: %{user: %{id: id}}} = socket
      )
      when id != kicked_user do
    {:noreply, assign(socket, activities: [activity])}
  end

  defdelegate handle_info(
                params,
                socket
              ),
              to: NoodlWeb.Live.Messaging.Chat

  def too_early?(session, now) do
    %{timezone: timezone} = session.event
    start_time = Timex.to_datetime(session.start_datetime, timezone)
    thirty_minutes_before = Timex.shift(start_time, minutes: -30)

    Timex.before?(now, thirty_minutes_before)
  end

  def pretty_activity_time(date, timezone) do
    utc_time = DateTime.from_naive!(date, "Etc/UTC")
    date = Timex.to_datetime(utc_time, timezone)
    Timex.format!(date, "%I:%M %P", :strftime)
  end

  defdelegate within_allowed_time?(a, b), to: SessionView
  defdelegate format_session_start_time(a, b), to: SessionView
end
