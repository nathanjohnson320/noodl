defmodule Noodl.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false
  alias Noodl.Repo

  alias Noodl.Messages.GroupMessage
  alias Noodl.Messages.Message

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(%Message{} = message, attrs \\ %{}) do
    message
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    message
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{source: %Message{}}

  """
  def change_message(%Message{} = message) do
    Message.changeset(message, %{})
  end

  def list_messages_for_event(event_id) do
    query =
      from m in Message,
        select: m,
        preload: [:user],
        where: m.event_id == ^event_id

    Repo.all(query)
  end

  def list_messages_for_session(session_id, limit \\ 10) do
    query =
      from m in Message,
        preload: [:user],
        where: m.session_id == ^session_id,
        order_by: [desc: m.inserted_at],
        limit: ^limit

    query |> Repo.all() |> Enum.reverse()
  end

  alias Noodl.Messages.Group

  @doc """
  Returns the list of groups.

  ## Examples

      iex> list_groups()
      [%Group{}, ...]

  """
  def list_groups do
    Repo.all(Group)
  end

  @doc """
  Gets a single group.

  Raises `Ecto.NoResultsError` if the Group does not exist.

  ## Examples

      iex> get_group!(123)
      %Group{}

      iex> get_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_group!(id), do: Repo.get!(Group, id)

  def get_or_create_group(users) do
    ids = Enum.map(users, & &1.id) |> Enum.sort()
    group = from(g in Group, where: g.users == ^ids) |> Repo.one()

    case group do
      nil ->
        create_group(%{"users" => ids})

      group ->
        {:ok, group}
    end
  end

  @doc """
  Creates a group.

  ## Examples

      iex> create_group(%{field: value})
      {:ok, %Group{}}

      iex> create_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a group.

  ## Examples

      iex> update_group(group, %{field: new_value})
      {:ok, %Group{}}

      iex> update_group(group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a group.

  ## Examples

      iex> delete_group(group)
      {:ok, %Group{}}

      iex> delete_group(group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking group changes.

  ## Examples

      iex> change_group(group)
      %Ecto.Changeset{data: %Group{}}

  """
  def change_group(%Group{} = group, attrs \\ %{}) do
    Group.changeset(group, attrs)
  end

  @doc """
  Returns the list of group_messages.

  ## Examples

      iex> list_group_messages()
      [%GroupMessage{}, ...]

  """
  def list_group_messages do
    Repo.all(GroupMessage)
  end

  def list_group_messages_for_users(users) do
    ids = Enum.map(users, & &1.id) |> Enum.sort()

    from(g in Group,
      join: m in assoc(g, :messages),
      where: g.users == ^ids,
      select: m
    )
    |> Repo.all()
  end

  @doc """
  Gets a single group_message.

  Raises `Ecto.NoResultsError` if the Group message does not exist.

  ## Examples

      iex> get_group_message!(123)
      %GroupMessage{}

      iex> get_group_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_group_message!(id), do: Repo.get!(GroupMessage, id)

  @doc """
  Creates a group_message.

  ## Examples

      iex> create_group_message(%{field: value})
      {:ok, %GroupMessage{}}

      iex> create_group_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group_message(attrs \\ %{}) do
    %GroupMessage{}
    |> GroupMessage.changeset(attrs)
    |> Repo.insert()
  end

  def create_group_message!(message, attrs) do
    message
    |> GroupMessage.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Updates a group_message.

  ## Examples

      iex> update_group_message(group_message, %{field: new_value})
      {:ok, %GroupMessage{}}

      iex> update_group_message(group_message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_group_message(%GroupMessage{} = group_message, attrs) do
    group_message
    |> GroupMessage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a group_message.

  ## Examples

      iex> delete_group_message(group_message)
      {:ok, %GroupMessage{}}

      iex> delete_group_message(group_message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group_message(%GroupMessage{} = group_message) do
    Repo.delete(group_message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking group_message changes.

  ## Examples

      iex> change_group_message(group_message)
      %Ecto.Changeset{data: %GroupMessage{}}

  """
  def change_group_message(%GroupMessage{} = group_message, attrs \\ %{}) do
    GroupMessage.changeset(group_message, attrs)
  end
end
