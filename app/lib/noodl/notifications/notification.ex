defmodule Noodl.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notifications" do
    field :content, :string
    field :is_read, :boolean, default: false
    field :priority, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:content, :is_read, :priority, :user_id])
    |> validate_required([:content])
  end
end
