defmodule Noodl.Events.Session.NameSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug
end

defmodule Noodl.Events.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noodl.Accounts.User
  alias Noodl.Events.{Event, Recording, Proposal}
  alias Noodl.Events.Session.NameSlug

  @derive {Jason.Encoder,
           only: [
             :id,
             :audience,
             :name,
             :description,
             :status,
             :start_datetime,
             :end_datetime,
             :topic,
             :type,
             :slug,
             :host_id,
             :event_id
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sessions" do
    field :audience, :string

    field :live_stream_id, :string
    field :name, :string
    field :description, :string

    field :playback_url, :string
    field :stream_key, :string
    field :status, :string, default: "initialized"

    field :start_datetime, :utc_datetime
    field :end_datetime, :utc_datetime

    field :topic, :string
    field :type, :string, default: "keynote"
    field :slug, NameSlug.Type
    field :auto_generate_speaker, :boolean, virtual: true, default: true

    field(:spectators, :boolean, default: false)
    field(:max_spectators, :integer)

    belongs_to :event, Event
    belongs_to :host, User
    belongs_to :proposal, Proposal

    has_many :recordings, Recording

    timestamps()
  end

  def types(), do: ["keynote", "video_conference"]

  @doc false
  def changeset(%__MODULE__{} = session, event, attrs \\ %{}) do
    session
    |> cast(attrs, [
      :audience,
      :auto_generate_speaker,
      :description,
      :event_id,
      :end_datetime,
      :host_id,
      :live_stream_id,
      :max_spectators,
      :name,
      :playback_url,
      :proposal_id,
      :spectators,
      :start_datetime,
      :status,
      :stream_key,
      :topic,
      :type
    ])
    |> validate_required([
      :name,
      :topic,
      :audience,
      :start_datetime,
      :end_datetime,
      :type,
      :host_id
    ])
    |> NameSlug.maybe_generate_slug()
    |> unique_constraint(:name,
      name: :sessions_event_id_name_index,
      message: "Session with that name already exists for this event"
    )
    |> validate_inclusion(:type, types())
    |> validate_start(:start_datetime, event: event)
    |> validate_end(:end_datetime, event: event)
  end

  def validate_start(changeset, field, [event: event] = options) do
    now = Timex.now(event.timezone)

    validate_change(changeset, field, fn _, date ->
      start_datetime = Timex.to_datetime(event.start_datetime, event.timezone)
      zone = Timex.Timezone.get(event.timezone)
      offset = Timex.Timezone.diff(date, zone)

      date =
        Timex.to_datetime(date, event.timezone)
        |> Timex.shift(seconds: -1 * offset)

      error =
        cond do
          Timex.before?(date, now) ->
            "A session cannot start in the past."

          Timex.before?(date, start_datetime) ->
            "A session cannot start before the event does."

          true ->
            nil
        end

      if is_nil(error) do
        []
      else
        [{:session_duration, options[:message] || error}]
      end
    end)
  end

  def validate_end(changeset, field, [event: event] = options) do
    validate_change(changeset, field, fn _, date ->
      {_, start_datetime} = fetch_field(changeset, :start_datetime)
      start_datetime = Timex.to_datetime(start_datetime, event.timezone)
      end_datetime = Timex.to_datetime(event.end_datetime, event.timezone)
      date = Timex.to_datetime(date, event.timezone)

      error =
        cond do
          Timex.after?(date, end_datetime) ->
            "A session cannot end after the event does."

          Timex.before?(date, start_datetime) ->
            "A session's start time must be before its end time."

          true ->
            nil
        end

      if is_nil(error) do
        []
      else
        [{:session_duration, options[:message] || error}]
      end
    end)
  end
end
