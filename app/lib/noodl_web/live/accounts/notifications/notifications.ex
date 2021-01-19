defmodule NoodlWeb.Live.Accounts.Notifications do
  @moduledoc ~S"""
  LiveView for the accounts notifications page.
  """
  use NoodlWeb, :live_view

  alias Noodl.Notifications

  def mount(_params, %{"user" => id} = session, socket) do
    notifications = Notifications.get_notifications_for_user(id)

    with_checked = Enum.map(notifications, fn n -> Map.put(n, :checked, false) end)

    {:ok,
     socket
     |> Authentication.assign_user(session)
     |> assign(
       notifications: with_checked,
       is_multi_checked: false,
       has_checked: false
     )}
  end

  def handle_event("mark_read", _, %{assigns: %{notifications: notifications}} = socket) do
    to_mark_read = Enum.filter(notifications, fn n -> n.checked end) |> Enum.map(fn n -> n.id end)

    case Notifications.bulk_update_notifications(to_mark_read, set: [is_read: true]) do
      {_, nil} ->
        {:noreply,
         socket
         |> put_flash(:info, "Notifications updated successfully!")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "There was an error updating your notifications. Please try again.")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}
    end
  end

  def handle_event("delete", _, %{assigns: %{notifications: notifications}} = socket) do
    to_delete = Enum.map(notifications, fn n -> n.id end)

    case Notifications.bulk_delete_notifications(to_delete) do
      {_, nil} ->
        {:noreply,
         socket
         |> put_flash(:info, "Notifications deleted successfully!")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "There was an error updating your notifications. Please try again.")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}
    end
  end

  def handle_event(
        "update",
        %{"_target" => [target]},
        %{assigns: %{notifications: notifications}} = socket
      ) do
    with_update =
      Enum.map(notifications, fn n ->
        case n.id == target do
          true -> Map.put(n, :checked, !n.checked)
          _ -> n
        end
      end)

    has_checked = Enum.find(with_update, fn n -> n.checked end)

    case has_checked do
      nil -> {:noreply, assign(socket, has_checked: false, notifications: with_update)}
      _ -> {:noreply, assign(socket, has_checked: true, notifications: with_update)}
    end
  end

  def handle_event(
        "multi_select",
        _,
        %{assigns: %{notifications: notifications, is_multi_checked: is_multi_checked}} = socket
      ) do
    with_checked = Enum.map(notifications, fn n -> Map.put(n, :checked, !is_multi_checked) end)
    has_checked = Enum.find(with_checked, fn n -> n.checked end)

    {:noreply,
     assign(socket,
       notifications: with_checked,
       is_multi_checked: !is_multi_checked,
       has_checked: !!has_checked
     )}
  end

  def format_created_at(%{inserted_at: inserted_at}) do
    Timex.from_now(inserted_at)
  end

  def get_notification_classes(%{is_read: true}),
    do: "pl-4 text-sm text-gray-900 opacity-50 line-through"

  def get_notification_classes(%{is_read: false}),
    do: "pl-4 text-sm text-gray-900"
end
