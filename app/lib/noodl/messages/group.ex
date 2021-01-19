defmodule Noodl.Messages.Group do
  @moduledoc """
  Groups are a collection of users. Primary used for messaging.
  I guess it could be used for other things too.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Messages.GroupMessage

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "groups" do
    field :users, {:array, :binary_id}

    has_many :messages, GroupMessage

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:users])
    |> validate_required([:users])
  end
end
