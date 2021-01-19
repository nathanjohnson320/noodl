defmodule Noodl.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias Noodl.Repo

  alias Noodl.Notifications.Notification

  @doc """
  Gets a single notification.

  Raises `Ecto.NoResultsError` if the Notification does not exist.

  ## Examples

      iex> get_notification!(123)
      %Notification{}

      iex> get_notification!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notification!(id), do: Repo.get!(Notification, id)

  @doc """
  Creates a notification.

  ## Examples

      iex> create_notification(%{field: value})
      {:ok, %Notification{}}

      iex> create_notification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a notification.

  ## Examples

      iex> update_notification(notification, %{field: new_value})
      {:ok, %Notification{}}

      iex> update_notification(notification, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification(%Notification{} = notification, attrs) do
    notification
    |> Notification.changeset(attrs)
    |> Repo.update()
  end

  def bulk_update_notifications(notifications, updates) do
    from(n in Notification, where: n.id in ^notifications)
    |> Repo.update_all(updates)
  end

  def bulk_delete_notifications(notifications) do
    from(n in Notification, where: n.id in ^notifications)
    |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification changes.

  ## Examples

      iex> change_notification(notification)
      %Ecto.Changeset{source: %Notification{}}

  """
  def change_notification(%Notification{} = notification) do
    Notification.changeset(notification, %{})
  end

  def get_notifications_for_user(user) do
    query =
      from n in Notification,
        where: n.user_id == ^user

    Repo.all(query)
  end
end
