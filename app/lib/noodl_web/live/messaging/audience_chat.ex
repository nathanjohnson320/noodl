defmodule NoodlWeb.Live.Messaging.AudienceChat do
  @moduledoc """
  Chat Component for all the people in a stream
  """

  use NoodlWeb, :live_view

  alias Noodl.{Accounts, Events, Messages}
  alias Noodl.Messages.Message
  alias NoodlWeb.Endpoint

  @impl true
  def mount(
        _params,
        %{
          "user" => user,
          "session" => session,
          "channel_name" => channel_name,
          "user_timezone" => user_timezone
        },
        socket
      ) do
    is_user_banned = Events.user_banned(user.id, session.event_id)

    organizers =
      [:organizer, :creator]
      |> Accounts.list_event_members_with_roles(%{id: session.event_id})
      |> Enum.reduce(MapSet.new(), fn o, acc -> MapSet.put(acc, o.id) end)

    Endpoint.subscribe(channel_name)

    {:ok,
     socket
     |> assign(
       channel_name: channel_name,
       is_user_banned: is_user_banned,
       message_changeset: Message.changeset(%Message{user_id: user.id, session_id: session.id}),
       is_organizer: MapSet.member?(organizers, user.id),
       organizers: organizers,
       session: session,
       user: user,
       user_timezone: user_timezone
     ),
     temporary_assigns: [
       messages: Messages.list_messages_for_session(session.id)
     ]}
  end

  @impl true
  def handle_event(
        "delete_message",
        %{"message" => id},
        %{assigns: %{channel_name: channel_name}} = socket
      ) do
    with message <- Messages.get_message!(id),
         {:ok, _deleted} <- Messages.delete_message(message),
         :ok <- Endpoint.broadcast!(channel_name, "delete_message", %{id: id}) do
      {:noreply, socket}
    else
      _e ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "submit_message",
        %{"message" => params},
        %{
          assigns: %{
            user: user,
            session: session,
            messages: messages,
            channel_name: channel_name
          }
        } = socket
      ) do
    message = %Message{user_id: Map.get(user, :id), session_id: session.id}

    case Messages.create_message(message, params) do
      {:ok, message} ->
        merged_message = Map.merge(message, %{user: user})

        Endpoint.broadcast_from(self(), channel_name, "message_submitted", %{
          message: merged_message
        })

        {:noreply,
         assign(socket, %{
           messages: [merged_message | messages],
           message_changeset: Message.changeset(message, %{})
         })}

      {:error, changeset} ->
        {:noreply,
         assign(socket, %{
           message_changeset: changeset
         })}
    end
  end

  @impl true
  def handle_info(
        %{event: "message_submitted", payload: %{message: inc_message}},
        socket
      ) do
    {:noreply, assign(socket, messages: [inc_message])}
  end

  @impl true
  def handle_info(
        %{event: "delete_message", payload: %{id: id}},
        socket
      ) do
    {:noreply, socket |> push_event("delete_message", %{id: id})}
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
     |> redirect(
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
     |> redirect(
       to:
         Routes.events_session_dashboard_path(
           socket,
           :dashboard,
           session.event.slug,
           session.slug
         )
     )}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  def emojis do
    NoodlWeb.Emotes.get_emotes()
  end

  def format_time(time, tz) do
    utc_time = DateTime.from_naive!(time, "Etc/UTC")
    date = Timex.to_datetime(utc_time, tz)

    Timex.format!(
      date,
      "%l:%M %p",
      :strftime
    )
  end

  defdelegate is_organizer?(user, organizers), to: NoodlWeb.Live.Messaging.Chat
  defdelegate get_username(user), to: NoodlWeb.SharedView
  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
end
