defmodule Noodl.Ticketing.Refund do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Ticketing.Ticket

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "refunds" do
    field :amount, Money.Ecto.Amount.Type
    field :charge_id, :string
    field :status, :string
    field :stripe_id, :string

    belongs_to :ticket, Ticket

    timestamps()
  end

  @doc false
  def changeset(refund, attrs) do
    refund
    |> cast(attrs, [:charge_id, :stripe_id, :amount, :status, :ticket_id])
    |> validate_required([:charge_id, :stripe_id, :amount, :status])
  end
end
