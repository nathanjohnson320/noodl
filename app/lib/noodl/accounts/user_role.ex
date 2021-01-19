defmodule Noodl.Accounts.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.{Role, User}
  alias Noodl.Events.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_roles" do
    belongs_to :role, Role
    belongs_to :user, User
    belongs_to :event, Event

    timestamps()
  end

  @doc false
  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id, :event_id])
    |> validate_required([:user_id, :role_id, :event_id])
  end
end
