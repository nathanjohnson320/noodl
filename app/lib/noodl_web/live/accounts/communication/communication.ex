defmodule NoodlWeb.Live.Accounts.Communication do
  @moduledoc ~S"""
  LiveView for the accounts communication page.
  """
  use NoodlWeb, :live_view

  require Logger

  alias Noodl.{Accounts, Repo}
  alias Noodl.Accounts.Subscription

  @subscription_types ["session_start", "promotional", "new_events"]

  def mount(_params, session, socket) do
    %{assigns: %{user: user}} =
      socket
      |> Authentication.assign_user(session)

    user = Repo.preload(user, [:push_subscription, :subscriptions])

    {:ok,
     socket
     |> assign(
       user: user,
       push_subscription: nil,
       subscriptions:
         Enum.reduce(@subscription_types, %{}, fn type, acc ->
           sub =
             Enum.find(user.subscriptions, &(&1.type == type)) ||
               %Subscription{type: type, user_id: user.id, email: user.email}

           Map.put(acc, type, sub)
         end)
     )}
  end

  def handle_event("unsubscribe", _, %{assigns: %{push_subscription: subscription}} = socket) do
    {:ok, _push_sub} = Accounts.delete_push_subscription(subscription)
    {:noreply, socket |> assign(push_subscription: nil)}
  end

  def handle_event(
        "update_preferences",
        %{"preferences" => preferences},
        %{assigns: %{subscriptions: subscriptions}} = socket
      ) do
    Enum.map(subscriptions, fn {type, subscription} ->
      # "false" here means that they want to be unsubscribed which is unsubscribed: true
      subscription
      |> Accounts.change_subscription()
      |> Ecto.Changeset.put_change(:unsubscribed, preferences[type] == "false")
    end)
    |> Accounts.insert_or_update_subscriptions()
    |> case do
      {:ok, subscriptions} ->
        {:noreply,
         socket
         |> put_flash(:info, "Your notifications preferences have been updated.")
         |> assign(subscriptions: subscriptions)}

      _ ->
        {:noreply, socket |> put_flash(:info, "There was a problem updating your preferences.")}
    end
  end

  def handle_event(
        "existing_subscription",
        %{
          "keys" => %{
            "auth" => public_key,
            "p256dh" => private_key
          }
        },
        socket
      ) do
    subscription =
      Accounts.get_push_subscription_by!(public_key: public_key, private_key: private_key)

    {:noreply, socket |> assign(push_subscription: subscription)}
  end

  def handle_event("error", payload, socket) do
    Logger.error(inspect(payload))

    {:noreply, socket}
  end

  def handle_event(
        "enable_subscriptions",
        %{
          "endpoint" => endpoint,
          "keys" => %{
            "auth" => auth,
            "p256dh" => pk
          }
        },
        %{assigns: %{user: user}} = socket
      ) do
    case Accounts.create_push_subscription(%{
           "user_id" => user.id,
           "endpoint" => endpoint,
           "public_key" => auth,
           "private_key" => pk
         }) do
      {:ok, push_subscription} ->
        {:noreply,
         socket
         |> assign(push_subscription: push_subscription)}

      _e ->
        {:noreply,
         socket
         |> put_flash(:info, "Could not enable push notifications.")}
    end
  end

  def is_subscribed?(subscriptions, field) do
    is_nil(subscriptions[field]) ||
      not subscriptions[field].unsubscribed
  end
end
