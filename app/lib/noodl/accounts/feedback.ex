defmodule Noodl.Accounts.Feedback do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "feedback" do
    field :description, :string
    field :subject, :string
    field :type, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [:subject, :type, :description])
    |> validate_required([:subject, :type, :description])
  end
end
