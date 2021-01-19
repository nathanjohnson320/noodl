defmodule Noodl.Messages.GroupMessage do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User
  alias Noodl.Messages.Group

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "group_messages" do
    field :content, :string

    belongs_to :user, User
    belongs_to :group, Group

    timestamps()
  end

  @doc false
  def changeset(group_message, attrs \\ %{}) do
    group_message
    |> cast(attrs, [:content, :user_id, :group_id])
    |> validate_required([:content, :user_id, :group_id])
  end
end
