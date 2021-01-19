defmodule NoodlWeb.Live.Events.Session.Dashboard do
  @moduledoc ~S"""
  LiveView for the exp dash
  """
  use NoodlWeb, :live_view

  alias Noodl.{Events, Meta}
  alias Noodl.Events.Event.Session
  alias NoodlWeb.{EventsView, LayoutView}

  @impl true
  def mount(
        %{"event" => event, "session" => slug},
        %{"user" => _user} = session,
        socket
      ) do
    %{assigns: %{user: user}} = socket = Authentication.assign_user(socket, session)

    preloads = [
      :sessions,
      :sponsors
    ]

    event = Events.get_event_by!([slug: event], preloads)

    session =
      Events.get_session_by!([slug: slug, event_id: event.id], [
        :host,
        event: preloads
      ])

    pid = Session.initialize(session)
    session_state = Session.mounted(pid, session)

    role =
      cond do
        Events.is_host?(user, session) ->
          :host

        session.type == "video_conference" and MapSet.member?(session_state.presenters, user.id) ->
          :host

        true ->
          :audience
      end

    if role == :audience and not Events.has_viewer_abilities?(session, event, user) do
      {:ok,
       socket
       |> put_flash(:info, "Sorry, it looks like you havent purchased your ticket yet!")
       |> push_redirect(
         to:
           Routes.events_show_path(
             socket,
             :show,
             session.event.slug
           )
       )}
    else
      {:ok,
       socket
       |> assign(
         role: role,
         session: session,
         user_timezone: EventsView.user_timezone(socket)
       )}
    end
  end

  @impl true
  def mount(%{"event" => event, "session" => slug}, _session, socket) do
    preloads = [
      :sessions,
      :sponsors
    ]

    event = Events.get_event_by!([slug: event], preloads)

    session =
      Events.get_session_by!([slug: slug, event_id: event.id], [
        :host,
        event: preloads
      ])

    Session.initialize(session)

    {:ok,
     socket
     |> assign(
       role: :spectator,
       user: nil,
       session: session,
       user_timezone: EventsView.user_timezone(socket),
       meta: %Meta{
         title: session.name,
         description: session.description,
         image: EventsView.cover_photo_url(event),
         url:
           LayoutView.full_url(
             Routes.events_session_dashboard_path(
               socket,
               :dashboard,
               session.event.slug,
               session.slug
             )
           )
       }
     )}
  end
end
