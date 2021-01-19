defmodule Noodl.Messages.Message do
  @moduledoc """
  Schema for messages between users.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User
  alias Noodl.Events.{Event, Session}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string

    belongs_to :user, User
    belongs_to :event, Event
    belongs_to :session, Session

    timestamps()
  end

  @doc false
  def changeset(message, attrs \\ %{}) do
    message
    |> cast(attrs, [:content, :user_id, :event_id, :session_id])
    |> validate_required([:content, :user_id])
    |> validate_length(:content, max: 500)
  end
end
