defmodule NoodlWeb.Live.Messaging.DirectMessage do
  @moduledoc """
  Chat Component that only handles group messaging
  """

  use NoodlWeb, :live_view

  alias Noodl.Messages
  alias Noodl.Messages.GroupMessage
  alias NoodlWeb.Endpoint

  @impl true
  def mount(_params, %{"user" => user, "to" => to, "user_timezone" => timezone}, socket) do
    {:ok, group} = Messages.get_or_create_group([user, to])

    :ok = Endpoint.subscribe(channel_name(group))

    {:ok,
     socket
     |> assign(
       user: user,
       to: to,
       group: group,
       message_changeset: changeset(user, group),
       user_timezone: timezone
     ),
     temporary_assigns: [
       messages: Messages.list_group_messages_for_users([user, to])
     ]}
  end

  @impl true
  def handle_event(
        "submit_message",
        %{"message" => params},
        %{
          assigns: %{
            user: user,
            group: group,
            messages: messages
          }
        } = socket
      ) do
    message = %GroupMessage{user_id: user.id, group_id: group.id}

    message = Messages.create_group_message!(message, params) |> Map.merge(%{user: user})

    Endpoint.broadcast_from(self(), channel_name(group), "message_submitted", %{
      message: message
    })

    {:noreply,
     assign(socket, %{
       messages: [message | messages],
       message_changeset: changeset(user, group)
     })}
  end

  @impl true
  def handle_info(
        %{event: "message_submitted", payload: %{message: message}},
        socket
      ) do
    {:noreply, assign(socket, messages: [message])}
  end

  defp channel_name(group), do: "message:#{group.id}"

  defp changeset(user, group),
    do: GroupMessage.changeset(%GroupMessage{user_id: user.id, group_id: group.id})

  def format_time(time, tz) do
    utc_time = DateTime.from_naive!(time, "Etc/UTC")
    date = Timex.to_datetime(utc_time, tz)

    Timex.format!(
      date,
      "%l:%M %p",
      :strftime
    )
  end

  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
  defdelegate get_username(user), to: NoodlWeb.SharedView
end
