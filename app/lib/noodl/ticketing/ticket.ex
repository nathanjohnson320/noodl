defmodule Noodl.Ticketing.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User
  alias Noodl.Events.Event
  alias Noodl.Ticketing.{Refund, Release}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tickets" do
    field :code, :string
    field :expires_at, :utc_datetime
    field :name, :string
    field :paid, :boolean, default: false
    field :price_paid, Money.Ecto.Amount.Type
    field :charge_id, :string
    field :redeemed_at, :utc_datetime

    # Flag used to create tickets for anyone outside
    # of normal purchases.
    field :admin, :boolean, default: false

    belongs_to :user, User
    belongs_to :release, Release
    belongs_to :event, Event

    has_one :refund, Refund

    timestamps()
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [
      :name,
      :code,
      :expires_at,
      :paid,
      :charge_id,
      :price_paid,
      :redeemed_at,
      :admin
    ])
    |> validate_required([:name, :code, :expires_at, :paid])
  end
end
