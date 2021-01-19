defmodule NoodlWeb.Live.Events.Manage.Schedule do
  @moduledoc ~S"""
  LiveView for the session manage page.
  """
  use NoodlWeb, :live_view

  alias Noodl.{Accounts, Events}
  alias Noodl.Events.Session
  alias NoodlWeb.{AccountsView, EventsView, SessionView}
  alias NoodlWeb.Router.Helpers, as: Routes

  def mount(_params, %{"event" => event, "user" => user}, socket) do
    event = Events.get_event_by!(slug: event)

    session = new_session(event)

    changeset = Session.changeset(session, event, %{})

    sessions =
      Events.get_sessions_by_event(event.id)
      |> Events.sessions_by_day(event)

    speakers = Accounts.list_event_members_with_roles([:speaker], event)

    {:ok,
     assign(socket,
       sessions: sessions,
       session: session,
       changeset: changeset,
       is_edit_open: false,
       is_new_open: false,
       user: user,
       validating: false,
       speakers: for(speaker <- speakers, into: [], do: {get_username(speaker), speaker.id}),
       event: event
     )}
  end

  def handle_event(
        "new",
        _,
        %{assigns: %{event: event}} = socket
      ) do
    changeset =
      Session.changeset(
        new_session(event),
        event,
        %{}
      )

    {:noreply, assign(socket, is_new_open: true, is_edit_open: false, changeset: changeset)}
  end

  def handle_event(
        "edit",
        %{"id" => id},
        %{assigns: %{event: event}} = socket
      ) do
    session = Events.get_session_by!(id: id)
    changeset = Session.changeset(session, event, %{})

    {:noreply,
     assign(socket,
       is_new_open: false,
       is_edit_open: true,
       session: session,
       changeset: changeset
     )}
  end

  def handle_event(
        "validate",
        %{"session" => session_params},
        %{assigns: %{event: event, session: session}} = socket
      ) do
    changeset = Session.changeset(session, event, session_params)

    {:noreply,
     socket
     |> assign(validating: true, changeset: changeset)}
  end

  def handle_event(
        "cancel",
        _,
        socket
      ) do
    {:noreply, assign(socket, is_new_open: false, is_edit_open: false)}
  end

  def handle_event(
        "submit_new",
        %{"session" => session_params},
        %{assigns: %{event: event, session: session}} = socket
      ) do
    case Events.create_session(session, event, session_params) do
      {:ok, _session} ->
        {:noreply,
         socket
         |> put_flash(:info, "Session #{session_params["name"]} created successfully!")
         |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :schedule))}

      {:error, :session, %Ecto.Changeset{} = changeset, _} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:invalid_time, msg} ->
        {:noreply, socket |> put_flash(:error, msg)}
    end
  end

  def handle_event(
        "submit_edit",
        %{"session" => session_params},
        %{assigns: %{event: event, session: session}} = socket
      ) do
    case Events.update_session(session, event, session_params) do
      {:ok, _session} ->
        {:noreply,
         socket
         |> put_flash(:info, "Session #{session_params["name"]} updated successfully!")
         |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :schedule))}

      {:error, :session, %Ecto.Changeset{} = changeset, _} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:invalid_time, msg} ->
        {:noreply, socket |> put_flash(:error, msg)}
    end
  end

  def new_session(event) do
    %Session{
      event_id: event.id,
      start_datetime: start_datetime(event),
      end_datetime: end_datetime(event)
    }
  end

  def end_datetime(event) do
    event.end_datetime
    |> Timex.to_datetime()
  end

  def start_datetime(event) do
    event.start_datetime
    |> Timex.to_datetime()
  end

  def session_start(session) do
    session.start_datetime
    |> Timex.format!("%l:%M %P", :strftime)
  end

  defdelegate profile_photo_url(a), to: AccountsView
  defdelegate pretty_manage_date(a, b), to: EventsView
  defdelegate user_timezone(socket), to: EventsView
  defdelegate pretty_event_date(a, b), to: EventsView
  defdelegate get_username(a), to: NoodlWeb.SharedView
end
