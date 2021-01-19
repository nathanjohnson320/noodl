defmodule Noodl.Events.EventBan do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User
  alias Noodl.Events.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "event_bans" do
    belongs_to :user, User
    belongs_to :event, Event

    timestamps()
  end

  @doc false
  def changeset(event_ban, attrs \\ %{}) do
    event_ban
    |> cast(attrs, [:user_id, :event_id])
    |> validate_required([:user_id, :event_id])
  end
end
