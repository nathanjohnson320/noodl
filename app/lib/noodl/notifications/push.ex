defmodule Noodl.Notifications.Push do
  require Logger

  alias Noodl.Accounts
  alias Noodl.Events

  def send_push(subscription, body) do
    body = Jason.encode!(body)

    {:ok, response} =
      WebPushEncryption.send_web_push(
        body,
        %{
          keys: %{
            auth: subscription.public_key,
            p256dh: subscription.private_key
          },
          endpoint: subscription.endpoint
        }
      )

    case response do
      %HTTPoison.Response{
        body: "push subscription has unsubscribed or expired.\n"
      } ->
        {:ok, subscription} =
          subscription.id
          |> Accounts.get_push_subscription!()
          |> Accounts.delete_push_subscription()

        Logger.error("user #{subscription.user_id} deleted their push notifications")
        :ok

      %HTTPoison.Response{
        status_code: 201
      } ->
        :ok
    end
  end

  @doc ~S"""
  Blast everyone that events/sessions are about to start
  """
  def events_starting(interval) do
    Events.list_sessions_about_to_start(interval)
    |> Enum.map(fn %{
                     name: event_name,
                     session: session_name,
                     user: %{
                       email: _email,
                       push_subscription: push
                     }
                   } ->
      # TODO: send email here too
      if not is_nil(push) do
        send_push(push, %{
          title: "NoodlTV \"#{event_name}\"",
          body: "\"#{session_name}\" is starting in the next #{interval} minutes"
        })
      end
    end)
  end
end
