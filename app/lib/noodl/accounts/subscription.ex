defmodule Noodl.Accounts.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "subscriptions" do
    field :email, :string
    field :type, :string
    field :unsubscribed, :boolean, default: false

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:type, :email, :unsubscribed, :user_id])
    |> validate_required([:type, :email, :unsubscribed])
    |> unique_constraint([:email, :type])
  end
end
