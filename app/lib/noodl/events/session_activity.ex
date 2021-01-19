defmodule Noodl.Events.SessionActivity do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User
  alias Noodl.Events.Session

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]
  schema "session_activities" do
    field :content, :string

    belongs_to :session, Session
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(activity, attrs \\ %{}) do
    activity
    |> cast(attrs, [:user_id, :session_id, :content])
    |> validate_required([:user_id, :session_id, :content])
  end
end
