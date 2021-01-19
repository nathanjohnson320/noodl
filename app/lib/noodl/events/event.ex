defmodule Noodl.Events.Event.NameSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug
end

defmodule Noodl.Events.Event do
  @moduledoc """
  Event Schema
  """

  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  alias Noodl.Accounts.User
  alias Noodl.Accounts.UserRole

  alias Noodl.Events.{Session, Sponsor}
  alias Noodl.Ticketing.Release

  alias Noodl.Events.Event.NameSlug
  alias Noodl.Uploaders.CoverPhoto
  alias Noodl.Ticketing.Ticket

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "events" do
    field(:name, :string)
    field(:description, :string)

    field(:start_datetime, :utc_datetime)

    field(:end_datetime, :utc_datetime)

    field(:is_recurring, :boolean)
    field(:website, :string)
    field(:phone, :string)
    field(:language, :string, default: "English")
    field(:timezone, :string, default: "America/New_York")
    field(:cover_photo, CoverPhoto.Type)

    field(:is_public, :boolean)
    field(:paid_out, :boolean, default: false)
    field(:is_live, :boolean, default: false)

    field(:contact_email, :string)
    field(:contact_phone, :string)
    field(:topic, :string)

    field(:proposal_deadline, :naive_datetime)

    field(:slug, NameSlug.Type)

    has_many(:releases, Release)
    belongs_to(:creator, User)

    has_many(:sponsors, Sponsor)
    has_many(:tickets, Ticket)
    has_many(:sessions, Session)
    has_many(:user_roles, UserRole)

    timestamps()
  end

  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [
      :name,
      :description,
      :start_datetime,
      :end_datetime,
      :is_recurring,
      :language,
      :website,
      :timezone,
      :is_public,
      :proposal_deadline,
      :paid_out,
      :contact_email,
      :contact_phone,
      :topic,
      :is_live
    ])
    |> validate_required(
      [
        :name,
        :description,
        :start_datetime,
        :end_datetime,
        :language,
        :timezone,
        :topic
      ],
      message: "Missing required fields"
    )
    |> validate_length(:name,
      min: 1,
      max: 256,
      message: "Event name must be between 1 and 256 characters"
    )
    |> validate_date_after(:start_datetime)
    |> validate_start_after_end(:start_datetime)
    |> unique_constraint(:name)
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
    |> cast_attachments(attrs, [:cover_photo])
  end

  def validate_date_after(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, date ->
      timezone = get_change(changeset, :timezone, changeset.data.timezone)
      now = Timex.now(timezone)
      zone = Timex.Timezone.get(timezone)
      offset = Timex.Timezone.diff(date, zone)

      date =
        Timex.to_datetime(date, timezone)
        |> Timex.shift(seconds: -1 * offset)

      if Timex.before?(now, date) do
        []
      else
        [{field, options[:message] || "cannot be in past"}]
      end
    end)
  end

  def validate_start_after_end(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, date ->
      {_, end_datetime} = fetch_field(changeset, :end_datetime)

      if Timex.diff(end_datetime, date) > 0 do
        []
      else
        [{field, options[:message] || "cannot be after end date"}]
      end
    end)
  end
end
