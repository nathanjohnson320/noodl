defmodule Noodl.Accounts.User do
  @moduledoc """
  User Schema
  """

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.{PushSubscription, Subscription, UserRole}
  alias Noodl.Ticketing.Ticket
  alias Noodl.Uploaders.ProfilePhoto

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :firstname, :string
    field :lastname, :string
    field :password_hash, :string
    field :stripe_account, :string
    field :confirmed, :boolean, default: false
    field :display_name, :string
    field :recording_id, :integer
    field :social_link, :string
    field :social_username, :string

    field :profile_photo, ProfilePhoto.Type

    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    has_many :tickets, Ticket
    has_many :push_subscription, PushSubscription
    has_many :subscriptions, Subscription
    has_many :user_roles, UserRole

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :firstname,
      :lastname,
      :email,
      :password,
      :password_confirmation,
      :stripe_account,
      :confirmed,
      :recording_id,
      :social_link,
      :social_username
    ])
    |> validate_required([:firstname, :lastname, :email],
      message: "Missing required fields"
    )
    |> validate_length(:email,
      min: 6,
      max: 256,
      message: "Email must be between 6 and 256 characters"
    )
    |> validate_length(:display_name, max: 64)
    |> unique_constraint(:email, message: "Email is invalid")
  end

  def signup_changeset(user, attrs) do
    user
    |> cast(attrs, [:firstname, :lastname, :email, :password, :password_confirmation])
    |> validate_required([:email, :password, :password_confirmation],
      message: "Missing required fields"
    )
    |> validate_length(:email,
      min: 6,
      max: 256,
      message: "Email must be between 6 and 256 characters"
    )
    |> validate_length(:password,
      min: 6,
      max: 64,
      message: "Password must be between 6 and 64 characters"
    )
    |> validate_length(:display_name, max: 64)
    |> unique_constraint(:email, message: "Email is invalid")
    |> validate_confirmation(:password, message: "Passwords do not match")
  end

  def oauth_changeset(user, attrs) do
    user
    |> cast(attrs, [:firstname, :lastname, :email, :confirmed])
    |> validate_required([:email],
      message: "Missing required fields"
    )
    |> validate_length(:email,
      min: 6,
      max: 256,
      message: "Email must be between 6 and 256 characters"
    )
    |> validate_length(:display_name, max: 64)
    |> unique_constraint(:email, message: "Email is invalid")
  end

  def login_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
  end

  def forgot_password_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :firstname,
      :lastname,
      :email,
      :confirmed,
      :display_name,
      :social_link,
      :social_username
    ])
    |> validate_required([:email],
      message: "Missing required fields"
    )
    |> validate_length(:display_name, max: 64)
  end

  def password_reset_changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation],
      message: "Missing required fields"
    )
    |> validate_length(:password,
      min: 6,
      max: 64,
      message: "Password must be between 6 and 64 characters"
    )
    |> validate_confirmation(:password, message: "Passwords do not match")
  end

  def add_password(%{changes: %{password: password}} = user) do
    password_hash = Argon2.hash_pwd_salt(password)

    user
    |> put_change(:password_hash, password_hash)
  end

  def add_password(changeset), do: changeset

  def validate_password(changeset, field, _options \\ []) do
    validate_change(changeset, field, fn _, password ->
      {:data, password_hash} = fetch_field(changeset, :password_hash)

      case Argon2.verify_pass(password, password_hash) do
        true ->
          []

        false ->
          [{field, "Invalid email or password"}]
      end
    end)
  end
end
