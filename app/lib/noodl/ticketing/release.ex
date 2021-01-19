defmodule Noodl.Ticketing.Release do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User
  alias Noodl.Events.Event
  alias Noodl.Ticketing.Ticket

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "releases" do
    field :default_quantity, :integer, default: 1
    field :description, :string
    field :end_at, :utc_datetime
    field :start_at, :utc_datetime
    field :max_tickets_per_person, :integer, default: 1
    field :price, Money.Ecto.Amount.Type
    field :pricing_type, :string, default: "paid"
    field :quantity, :integer, default: 15
    field :title, :string

    field :purchase_quantity, :integer, default: 0, virtual: true

    belongs_to :event, Event
    belongs_to :user, User

    has_many :tickets, Ticket, on_delete: :nilify_all

    timestamps()
  end

  @doc false
  def changeset(release, attrs) do
    release
    |> cast(attrs, [
      :title,
      :default_quantity,
      :description,
      :end_at,
      :max_tickets_per_person,
      :price,
      :pricing_type,
      :quantity,
      :start_at
    ])
    |> set_price(attrs)
    |> validate_required([
      :title,
      :default_quantity,
      :end_at,
      :price,
      :pricing_type,
      :quantity,
      :start_at
    ])
    |> validate_quantity(:default_quantity)
    |> validate_quantity(:max_tickets_per_person)
  end

  defp validate_quantity(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, default_quantity ->
      {_, quantity} = fetch_field(changeset, :quantity)

      if default_quantity <= quantity do
        []
      else
        [{field, options[:message] || "cannot be more than quantity"}]
      end
    end)
  end

  defp set_price(changeset, %{"pricing_type" => "free"}) do
    Ecto.Changeset.put_change(changeset, :price, Money.new(0))
  end

  defp set_price(changeset, _attrs), do: changeset
end
