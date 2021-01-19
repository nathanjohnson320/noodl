defmodule Noodl.Events.Recording do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Events.Session

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "recordings" do
    field :external_id, :string
    field :resource_id, :string
    field :status, :string
    field :type, :string, default: "system"

    field :url, :string, virtual: true

    belongs_to :session, Session

    timestamps()
  end

  @doc false
  def changeset(recording, attrs) do
    recording
    |> cast(attrs, [:external_id, :resource_id, :status, :session_id, :type, :url])
    |> cast_url()
    |> validate_required([:session_id, :external_id, :type])
  end

  def cast_url(changeset) do
    type = get_field(changeset, :type)
    url = get_field(changeset, :url)

    case url do
      nil ->
        changeset

      "" ->
        changeset

      url ->
        parse_type(type, changeset, URI.parse(url))
    end
  end

  def parse_type("youtube", changeset, %URI{host: "youtu.be", path: "/" <> path}) do
    changeset |> put_change(:external_id, path)
  end

  def parse_type("youtube", changeset, %URI{
        host: "www.youtube.com",
        path: "/watch",
        query: query
      }) do
    case URI.decode_query(query) do
      %{"v" => version} ->
        changeset |> put_change(:external_id, version)

      _ ->
        changeset
    end
  end

  def parse_type(_type, changeset, _parsed), do: changeset
end
