defmodule Noodl.Accounts.PushSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "push_subscriptions" do
    field :endpoint, :string
    field :private_key, :string
    field :public_key, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(push_subscription, attrs) do
    push_subscription
    |> cast(attrs, [:endpoint, :private_key, :public_key, :user_id])
    |> validate_required([:endpoint, :private_key, :public_key, :user_id])
    |> unique_constraint([:endpoint, :private_key, :public_key])
  end
end
