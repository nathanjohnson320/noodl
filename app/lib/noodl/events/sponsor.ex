defmodule Noodl.Events.Sponsor do
  @moduledoc """
  Sponsor Schema
  """

  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  alias Noodl.Events.Event
  alias Noodl.Uploaders.SponsorPhoto

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sponsors" do
    field :company_info, :string
    field :description, :string
    field :image, SponsorPhoto.Type
    field :name, :string
    field :external_link, :string
    field :link_text, :string

    belongs_to :event, Event

    timestamps()
  end

  @doc false
  def changeset(sponsor, attrs) do
    sponsor
    |> cast(attrs, [
      :name,
      :description,
      :company_info,
      :event_id,
      :external_link,
      :link_text
    ])
    |> validate_required([:name, :event_id])
    |> unique_constraint(:name,
      name: :sponsors_event_id_name_index,
      message: "Sponsor with that name already exists for this event"
    )
  end
end
