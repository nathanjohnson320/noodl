defmodule NoodlWeb.Live.Events.Session.Dashboard.VideoConference do
  use NoodlWeb, :live_view

  alias Agora.AccessKey, as: Agora
  alias Noodl.Events
  alias Noodl.Events.Event.Session
  alias NoodlWeb.{EventsView, SessionView}
  alias NoodlWeb.Router.Helpers, as: Routes

  @app_id Application.get_env(:noodl, :agora_app_id, "")
  @certificate Application.get_env(:noodl, :agora_certificate, "")

  @impl true
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
    %{channel: channel_name} = Events.stream_channel_details(session)
    event = Events.get_event_by!(id: session.event_id)

    pid = Session.initialize(session)

    user = Events.generate_anonymous_user()

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
       pid: pid,
       presenters: presenters,
       role: :audience,
       session: session,
       time_elapsed: time_elapsed,
       user: user,
       user_timezone: user_timezone
     )}
  end

  def mount(
        _params,
        %{"user" => user, "session" => session, "role" => role, "user_timezone" => user_timezone},
        socket
      ) do
    %{channel: channel_name, message: message} = Events.stream_channel_details(session, user)
    event = Events.get_event_by!(id: session.event_id)

    pid = Session.initialize(session)

    # Preload the session state
    %{
      time_elapsed: time_elapsed,
      presenters: presenters
    } = Session.mounted(pid, session)

    future_sessions = Events.active_sessions_for_event(session.event)

    permissions =
      if role == :host do
        [
          :join_channel,
          :publish_audio,
          :publish_video,
          :publish_data
        ]
      else
        [:join_channel]
      end

    agora_token =
      Agora.new_token(@app_id, @certificate, channel_name, "#{user.recording_id}", permissions)

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
       role: role,
       session: session,
       time_elapsed: time_elapsed,
       user: user,
       user_timezone: user_timezone
     )}
  end

  @impl true
  def handle_event(
        "connected",
        _params,
        %{assigns: %{pid: pid}} = socket
      ) do
    :ok = Session.connected(pid)

    {:noreply, socket}
  end

  @impl true
  def handle_event("end_session", _params, %{assigns: %{pid: pid}} = socket) do
    Session.ended(pid)

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{event: "added_presenter", payload: %{presenter: presenter}},
        %{assigns: %{user: %{id: id} = user, channel_name: channel_name}} = socket
      ) do
    if id == presenter do
      permissions = [
        :join_channel,
        :publish_audio,
        :publish_video,
        :publish_data
      ]

      agora_token =
        Agora.new_token(@app_id, @certificate, channel_name, "#{user.recording_id}", permissions)

      {:noreply,
       socket
       |> push_event("change_presenter", %{
         agora_token: agora_token,
         role: :host
       })
       |> assign(
         agora_token: agora_token,
         role: :host
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        %{event: "removed_presenter", payload: %{presenter: presenter}},
        %{assigns: %{user: %{id: id} = user, channel_name: channel_name}} = socket
      ) do
    if id == presenter do
      permissions = [
        :join_channel
      ]

      agora_token =
        Agora.new_token(@app_id, @certificate, channel_name, "#{user.recording_id}", permissions)

      {:noreply,
       socket
       |> push_event("change_presenter", %{
         agora_token: agora_token,
         role: :audience
       })
       |> assign(
         agora_token: agora_token,
         role: :host
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        %{event: "session_error", payload: %{message: message}},
        socket
      ) do
    {:noreply, socket |> put_flash(:error, message)}
  end

  @impl true
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

  @impl true
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

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  def timer(time) do
    Timex.format!(time, "%T", :strftime)
  end

  def pretty_time(time, tz, desired_tz) do
    datetime = Events.appropriate_timezone(time, tz, desired_tz)

    Timex.format!(datetime, "%l:%M %p on %B %e", :strftime)
  end

  defdelegate cover_photo_url(exp), to: EventsView
  defdelegate within_allowed_time?(a, b), to: SessionView
end
