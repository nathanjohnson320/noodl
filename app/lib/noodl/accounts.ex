defmodule Noodl.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Ecto.Multi

  alias Noodl.Accounts.{User, UserRole}
  alias Noodl.Emails.Mailer
  alias Noodl.Image
  alias Noodl.Repo
  alias NoodlWeb.Email

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def list_confirmed_users do
    q = from(u in User, where: u.confirmed)
    Repo.all(q)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id) do
    query = from(u in User, where: u.id == ^id)

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}

      nil ->
        {:error, :not_found}

      _ ->
        {:error, :unknown}
    end
  end

  def get_user_by(params) do
    case Repo.get_by(User, params) do
      %User{} = user ->
        {:ok, user}

      nil ->
        {:error, :not_found}

      _ ->
        {:error, :unknown}
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    Multi.new()
    |> Multi.insert(
      :user,
      %User{}
      |> User.signup_changeset(attrs)
      |> User.add_password()
    )
    |> Multi.run(:email, fn _repo, %{user: user} ->
      message = Email.confirmation(user)

      Mailer.send_now(user.email, "account", message)
    end)
    |> Repo.transaction()
  end

  def create_oauth_user(attrs) do
    Multi.new()
    |> Multi.insert(
      :user,
      # if someone is coming in via oauth they have already confirmed their account
      # with the other IDP so we can assume that if oauth is good, they are good
      %User{confirmed: true}
      |> User.oauth_changeset(attrs)
    )
    |> Repo.transaction()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def update_user(%User{} = user, attrs, callback) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
    |> callback(callback)
  end

  def callback({:ok, user}, callback), do: callback.(user)
  def callback(error, _callback), do: error

  def update_profile_photo(user, path, entry) do
    user |> change_user() |> Image.add_file(:profile_photo, path, entry) |> Repo.update()
  end

  @doc """
  Updates a users password.

  ## Examples

      iex> password_reset(user, %{password: new_value})
      {:ok, %User{}}

  """
  def password_reset(user, attrs) do
    user
    |> User.password_reset_changeset(attrs)
    |> User.add_password()
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def login_user(%{"email" => email} = params) do
    with %User{email: email} = user when not is_nil(email) <- Repo.get_by(User, email: email),
         %{valid?: true} = changeset <- User.login_changeset(user, params),
         %{valid?: true} <- User.validate_password(changeset, :password) do
      {:ok, user}
    else
      nil ->
        {:error,
         %User{}
         |> User.login_changeset(params)
         |> Changeset.add_error(:email, "Email or password invalid")}

      changeset ->
        {:error, changeset}
    end
  end

  alias Noodl.Accounts.Feedback

  @doc """
  Returns the list of feedback.

  ## Examples

      iex> list_feedback()
      [%Feedback{}, ...]

  """
  def list_feedback do
    Repo.all(Feedback)
  end

  @doc """
  Gets a single feedback.

  Raises `Ecto.NoResultsError` if the Feedback does not exist.

  ## Examples

      iex> get_feedback!(123)
      %Feedback{}

      iex> get_feedback!(456)
      ** (Ecto.NoResultsError)

  """
  def get_feedback!(id), do: Repo.get!(Feedback, id)

  @doc """
  Creates a feedback.

  ## Examples

      iex> create_feedback(%{field: value})
      {:ok, %Feedback{}}

      iex> create_feedback(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_feedback(feedback, attrs \\ %{}) do
    feedback
    |> Feedback.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a feedback.

  ## Examples

      iex> update_feedback(feedback, %{field: new_value})
      {:ok, %Feedback{}}

      iex> update_feedback(feedback, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_feedback(%Feedback{} = feedback, attrs) do
    feedback
    |> Feedback.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a feedback.

  ## Examples

      iex> delete_feedback(feedback)
      {:ok, %Feedback{}}

      iex> delete_feedback(feedback)
      {:error, %Ecto.Changeset{}}

  """
  def delete_feedback(%Feedback{} = feedback) do
    Repo.delete(feedback)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feedback changes.

  ## Examples

      iex> change_feedback(feedback)
      %Ecto.Changeset{data: %Feedback{}}

  """
  def change_feedback(%Feedback{} = feedback, attrs \\ %{}) do
    Feedback.changeset(feedback, attrs)
  end

  alias Noodl.Accounts.Subscription

  @doc """
  Returns the list of subscriptions.

  ## Examples

      iex> list_subscriptions()
      [%Subscription{}, ...]

  """
  def list_subscriptions do
    Repo.all(Subscription)
  end

  @doc """
  Gets a single subscription.

  Raises `Ecto.NoResultsError` if the Subscription does not exist.

  ## Examples

      iex> get_subscription!(123)
      %Subscription{}

      iex> get_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subscription!(id), do: Repo.get!(Subscription, id)

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(%{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(subscription, %{field: new_value})
      {:ok, %Subscription{}}

      iex> update_subscription(subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  def insert_or_update_subscriptions(subscriptions) do
    subscriptions
    |> Enum.reduce(Multi.new(), fn subscription, transaction ->
      # The types are unique so we can do an upsert with that as the name
      Multi.insert_or_update(transaction, subscription.data.type, subscription)
    end)
    |> Repo.transaction()
  end

  @doc """
  Deletes a subscription.

  ## Examples

      iex> delete_subscription(subscription)
      {:ok, %Subscription{}}

      iex> delete_subscription(subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subscription changes.

  ## Examples

      iex> change_subscription(subscription)
      %Ecto.Changeset{data: %Subscription{}}

  """
  def change_subscription(%Subscription{} = subscription, attrs \\ %{}) do
    Subscription.changeset(subscription, attrs)
  end

  def is_unsubscribed?(email, type) when type in ["promotional"] do
    query =
      from(sub in Subscription,
        where: sub.type == ^type and sub.email == ^email
      )

    case Repo.one(query) do
      nil -> false
      _ -> true
    end
  end

  def is_unsubscribed?(_email, _type), do: false

  alias Noodl.Accounts.PushSubscription

  @doc """
  Returns the list of push_subscriptions.

  ## Examples

      iex> list_push_subscriptions()
      [%PushSubscription{}, ...]

  """
  def list_push_subscriptions do
    Repo.all(PushSubscription)
  end

  @doc """
  Gets a single push_subscription.

  Raises `Ecto.NoResultsError` if the Push subscription does not exist.

  ## Examples

      iex> get_push_subscription!(123)
      %PushSubscription{}

      iex> get_push_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_push_subscription!(id), do: Repo.get!(PushSubscription, id)

  def get_push_subscription_by!(params), do: Repo.get_by!(PushSubscription, params)

  @doc """
  Creates a push_subscription.

  ## Examples

      iex> create_push_subscription(%{field: value})
      {:ok, %PushSubscription{}}

      iex> create_push_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_push_subscription(attrs \\ %{}) do
    %PushSubscription{}
    |> PushSubscription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a push_subscription.

  ## Examples

      iex> update_push_subscription(push_subscription, %{field: new_value})
      {:ok, %PushSubscription{}}

      iex> update_push_subscription(push_subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_push_subscription(%PushSubscription{} = push_subscription, attrs) do
    push_subscription
    |> PushSubscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a push_subscription.

  ## Examples

      iex> delete_push_subscription(push_subscription)
      {:ok, %PushSubscription{}}

      iex> delete_push_subscription(push_subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_push_subscription(%PushSubscription{} = push_subscription) do
    Repo.delete(push_subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking push_subscription changes.

  ## Examples

      iex> change_push_subscription(push_subscription)
      %Ecto.Changeset{data: %PushSubscription{}}

  """
  def change_push_subscription(%PushSubscription{} = push_subscription, attrs \\ %{}) do
    PushSubscription.changeset(push_subscription, attrs)
  end

  alias Noodl.Accounts.Role

  @doc """
  Returns the list of roles.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    Repo.all(Role)
  end

  def list_manageable_roles() do
    from(r in Role, where: r.name not in ["creator"], order_by: r.name) |> Repo.all()
  end

  @doc """
  Gets a single role.

  Raises `Ecto.NoResultsError` if the Role does not exist.

  ## Examples

      iex> get_role!(123)
      %Role{}

      iex> get_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_role!(name) when is_atom(name), do: Repo.get_by(Role, name: to_string(name))
  def get_role!(id), do: Repo.get!(Role, id)

  @doc """
  Creates a role.

  ## Examples

      iex> create_role(%{field: value})
      {:ok, %Role{}}

      iex> create_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a role.

  ## Examples

      iex> update_role(role, %{field: new_value})
      {:ok, %Role{}}

      iex> update_role(role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_role(%Role{} = role, attrs) do
    role
    |> Role.changeset(attrs)
    |> Repo.update()
  end

  def update_user_roles(user, event, roles) do
    creator = get_role!(:creator)

    tx =
      Multi.delete_all(
        Multi.new(),
        :user_roles,
        from(ur in UserRole,
          where:
            ur.role_id not in [^creator.id] and ur.user_id == ^user.id and
              ur.event_id == ^event.id
        )
      )

    Enum.reduce(roles, tx, fn
      {role_id, "true"}, acc ->
        Multi.insert(
          acc,
          role_id,
          change_user_role(%UserRole{}, %{
            "user_id" => user.id,
            "role_id" => role_id,
            "event_id" => event.id
          })
        )

      _, acc ->
        acc
    end)
    |> Repo.transaction()
  end

  @doc """
  Deletes a role.

  ## Examples

      iex> delete_role(role)
      {:ok, %Role{}}

      iex> delete_role(role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_role(%Role{} = role) do
    Repo.delete(role)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking role changes.

  ## Examples

      iex> change_role(role)
      %Ecto.Changeset{data: %Role{}}

  """
  def change_role(%Role{} = role, attrs \\ %{}) do
    Role.changeset(role, attrs)
  end

  @doc """
  Returns the list of user_roles.

  ## Examples

      iex> list_user_roles()
      [%UserRole{}, ...]

  """
  def list_user_roles do
    Repo.all(UserRole)
  end

  @doc """
  Gets a single user_role.

  Raises `Ecto.NoResultsError` if the User role does not exist.

  ## Examples

      iex> get_user_role!(123)
      %UserRole{}

      iex> get_user_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_role!(id), do: Repo.get!(UserRole, id)

  @doc """
  Creates a user_role.

  ## Examples

      iex> create_user_role(%{field: value})
      {:ok, %UserRole{}}

      iex> create_user_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_role(attrs \\ %{}) do
    %UserRole{}
    |> UserRole.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_role.

  ## Examples

      iex> update_user_role(user_role, %{field: new_value})
      {:ok, %UserRole{}}

      iex> update_user_role(user_role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_role(%UserRole{} = user_role, attrs) do
    user_role
    |> UserRole.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_role.

  ## Examples

      iex> delete_user_role(user_role)
      {:ok, %UserRole{}}

      iex> delete_user_role(user_role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_role(%UserRole{} = user_role) do
    Repo.delete(user_role)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_role changes.

  ## Examples

      iex> change_user_role(user_role)
      %Ecto.Changeset{data: %UserRole{}}

  """
  def change_user_role(%UserRole{} = user_role, attrs \\ %{}) do
    UserRole.changeset(user_role, attrs)
  end

  def list_event_members_with_roles(roles, event, preloads \\ []) do
    roles = Enum.map(roles, &to_string/1)

    query =
      from(user in User,
        join: user_role in assoc(user, :user_roles),
        join: role in assoc(user_role, :role),
        where: role.name in ^roles and user_role.event_id == ^event.id
      )

    query |> Repo.all() |> Repo.preload(preloads)
  end

  def user_has_role?(nil, _event, _role), do: false

  def user_has_role?(user, event, role) do
    role = get_role!(role)

    query =
      from(user in User,
        join: user_role in assoc(user, :user_roles),
        where:
          user_role.user_id == ^user.id and user_role.role_id == ^role.id and
            user_role.event_id == ^event.id
      )

    case Repo.one(query) do
      nil -> {:error, :unauthorized}
      _ -> :ok
    end
  end
end
