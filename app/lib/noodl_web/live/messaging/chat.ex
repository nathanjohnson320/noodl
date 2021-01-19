defmodule NoodlWeb.Live.Messaging.Chat do
  @moduledoc """
  Chat Component that is also a live view module.
  """

  use NoodlWeb, :live_view

  require Logger

  alias Noodl.{Accounts, Events}
  alias Noodl.Events.EventBan
  alias Noodl.Events.Event.Session
  alias NoodlWeb.{Endpoint, Presence}

  @impl true
  def mount(
        _params,
        %{
          "session" => session,
          "user" => user,
          "role" => role,
          "channel_name" => channel_name,
          "user_timezone" => user_timezone
        },
        socket
      ) do
    pid = Session.initialize(session)
    %{presenters: presenters} = Session.mounted(pid, session)

    organizers =
      [:organizer, :creator]
      |> Accounts.list_event_members_with_roles(%{id: session.event_id})

    organizer =
      organizers
      |> Enum.find(&(&1.id == user.id))

    banned_users =
      Events.banned_users(session.event_id)
      |> Enum.reduce(MapSet.new(), fn o, acc -> MapSet.put(acc, o.user_id) end)

    Endpoint.subscribe(channel_name <> ":presence")
    Endpoint.subscribe(channel_name)
    Events.track_user(user, :audience, channel_name <> ":presence")

    {:ok,
     socket
     |> assign(
       banned_users: banned_users,
       channel_name: channel_name,
       chat_open: true,
       current_tab: :chat,
       direct_message: nil,
       is_organizer: not is_nil(organizer),
       organizers:
         organizers |> Enum.reduce(MapSet.new(), fn o, acc -> MapSet.put(acc, o.id) end),
       pid: pid,
       presenters: presenters,
       role: role,
       session: session,
       user: user,
       user_timezone: user_timezone,
       users: [],
       viewer_count: 0
     )}
  end

  @impl true
  def handle_event("close_chat", _, socket) do
    {:noreply, socket |> assign(chat_open: false)}
  end

  @impl true
  def handle_event("open_chat", _, socket) do
    {:noreply, socket |> assign(chat_open: true)}
  end

  @impl true
  def handle_event("add_presenter", %{"id" => id}, %{assigns: %{pid: pid, role: role}} = socket) do
    Session.add_presenter(pid, %{"id" => id, "role" => role})

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "remove_presenter",
        %{"id" => id},
        %{assigns: %{pid: pid, role: role}} = socket
      ) do
    Session.remove_presenter(pid, %{"id" => id, "role" => role})

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change_tab",
        %{"tab" => tab},
        %{assigns: %{current_tab: current_tab}} = socket
      ) do
    tab =
      case tab do
        "chat" -> :chat
        "users" -> :users
        "messages" -> :messages
        "direct_message" -> :direct_message
        _ -> :chat
      end

    if tab == current_tab do
      {:noreply,
       assign(socket,
         current_tab: :chat
       )}
    else
      {:noreply,
       assign(socket,
         current_tab: tab
       )}
    end
  end

  @impl true
  def handle_event(
        "kick",
        %{"id" => id},
        %{
          assigns: %{
            user: user,
            session: session,
            channel_name: channel_name,
            banned_users: banned_users
          }
        } = socket
      ) do
    {:ok, kicked_user} = Accounts.get_user(id)

    ban = %{user_id: id, event_id: session.event_id}

    activity = %{
      session_id: session.id,
      user_id: user.id,
      content: "#{user.firstname} has banned #{kicked_user.firstname} from the chat."
    }

    case Events.create_event_ban(%EventBan{}, ban, activity) do
      {:ok, %{event_ban: ban, session_activity: sa}} ->
        sa = Events.correct_timezone(sa, :inserted_at, session.event)
        Endpoint.broadcast!(channel_name, "kick_user", %{id: id, activity: sa})

        {:noreply, assign(socket, banned_users: MapSet.put(banned_users, ban.user_id))}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "unban",
        %{"id" => id},
        %{
          assigns: %{
            user: user,
            session: session,
            channel_name: channel_name,
            banned_users: banned_users
          }
        } = socket
      ) do
    {:ok, kicked_user} = Accounts.get_user(id)
    ban = Events.user_banned(id, session.event_id)

    activity = %{
      session_id: session.id,
      user_id: user.id,
      content: "#{user.firstname} has unbanned #{kicked_user.firstname} from the chat."
    }

    case Events.delete_event_ban(ban, activity) do
      {:ok, %{event_ban: ban, session_activity: sa}} ->
        sa = Events.correct_timezone(sa, :inserted_at, session.event)
        Endpoint.broadcast!(channel_name, "unban_user", %{id: id, activity: sa})

        {:noreply, assign(socket, banned_users: MapSet.delete(banned_users, ban.user_id))}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("direct_message", %{"user" => id}, socket) do
    {:noreply, socket} =
      handle_event(
        "change_tab",
        %{"tab" => "direct_message"},
        socket
      )

    {:noreply, socket |> assign(direct_message: Accounts.get_user!(id))}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: _payload},
        %{assigns: %{channel_name: channel_name}} = socket
      ) do
    users = (channel_name <> ":presence") |> Presence.get_users()
    {:noreply, assign(socket, users: users, viewer_count: Enum.count(users))}
  end

  @impl true
  def handle_info(
        %{event: "added_presenter", payload: %{presenters: presenters}},
        socket
      ) do
    {:noreply, socket |> assign(presenters: presenters)}
  end

  @impl true
  def handle_info(
        %{event: "removed_presenter", payload: %{presenters: presenters}},
        socket
      ) do
    {:noreply, socket |> assign(presenters: presenters)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  def user_banned?(%{id: id}, banned_users) do
    MapSet.member?(banned_users, id)
  end

  def non_anonymous_users(users) do
    Enum.filter(users, &(&1.recording_id != "0"))
  end

  def is_organizer?(%{user_id: user_id}, organizers) do
    MapSet.member?(organizers, user_id)
  end

  defdelegate get_username(user), to: NoodlWeb.SharedView
  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
end
