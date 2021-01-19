defmodule Noodl.Events.Proposal do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Events.Session
  alias Noodl.Events.Event
  alias Noodl.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "proposals" do
    field :audience, :string
    field :description, :string
    field :notes, :string
    field :tags, {:array, :string}
    field :title, :string
    field :topic, :string
    field :company_description, :string
    field :company_name, :string
    field :approved, :boolean, default: nil

    belongs_to :event, Event
    belongs_to :user, User
    has_one :session, Session

    timestamps()
  end

  @doc false
  def changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [
      :title,
      :topic,
      :audience,
      :description,
      :notes,
      :tags,
      :approved,
      :event_id,
      :user_id,
      :company_name,
      :company_description
    ])
    |> parse_tags(attrs)
    |> validate_required([:title, :topic, :audience, :description, :notes, :tags])
    |> unique_constraint(
      [:user_id, :event_id],
      message: "You've already submitted a proposal for this event."
    )
  end

  defp parse_tags(changeset, %{"raw_tags" => raw_tags}) do
    changeset
    |> put_change(:tags, String.split(raw_tags, ",") |> Enum.map(&String.trim/1) |> Enum.uniq())
  end

  defp parse_tags(changeset, _attrs), do: changeset
end
