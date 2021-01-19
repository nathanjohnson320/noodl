defmodule Noodl.Events do
  @moduledoc """
  The Events context.
  """

  use Timex
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Noodl.Accounts

  alias Noodl.Events.{
    Event,
    Session,
    EventBan,
    SessionActivity,
    Sponsor
  }

  alias Noodl.{Image, Repo, Ticketing}
  alias Noodl.Messages.Message
  alias Noodl.Emails.Mailer
  alias NoodlWeb.Email

  @doc """
  Returns the list of events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_events(limit \\ 10) do
    query =
      from(e in Event,
        where: e.is_live,
        preload: [:releases],
        limit: ^limit
      )

    Repo.all(query)
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Gets a single event by one of its fields

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event_by!(slug: "123")
      %Event{}

      iex> get_event_by!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event_by!(fields, preloads \\ []),
    do: Repo.get_by!(Event, fields) |> Repo.preload(preloads)

  def get_event_by(fields, preloads \\ []) do
    case Repo.get_by(Event, fields) do
      nil ->
        {:error, :not_found}

      event ->
        {:ok,
         event
         |> Repo.preload(preloads)}
    end
  end

  def is_organizer?(user, event) do
    case Accounts.user_has_role?(user, event, :organizer) do
      :ok ->
        true

      _ ->
        false
    end
  end

  def is_host?(user, session) do
    session.host_id == user.id
  end

  def is_creator?(user, event) do
    case Accounts.user_has_role?(user, event, :creator) do
      :ok ->
        true

      _ ->
        false
    end
  end

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(%Event{} = event, attrs, callback) do
    Multi.new()
    |> Multi.insert(
      :event,
      event
      |> Event.changeset(attrs)
    )
    |> Multi.insert(:creator_ticket, fn %{event: event} ->
      Ticketing.create_admin_ticket(event, event.creator_id)
    end)
    |> Multi.insert(:creator_role, fn %{event: event} ->
      role = Accounts.get_role!(:creator)

      Accounts.change_user_role(%Accounts.UserRole{}, %{
        user_id: event.creator_id,
        role_id: role.id,
        event_id: event.id
      })
    end)
    |> Repo.transaction()
    |> callback(callback)
  end

  def callback({:ok, event}, callback), do: callback.(event)
  def callback(error, _callback), do: error

  def update_cover_photo(event, path, entry) do
    event |> change_event() |> Image.add_file(:cover_photo, path, entry) |> Repo.update()
  end

  def create_event_ban(%EventBan{} = ban, attrs, session_activity) do
    Multi.new()
    |> Multi.insert(:event_ban, ban |> EventBan.changeset(attrs))
    |> Multi.insert(
      :session_activity,
      SessionActivity.changeset(%SessionActivity{}, session_activity)
    )
    |> Repo.transaction()
  end

  def delete_event_ban(%EventBan{} = ban, session_activity) do
    Multi.new()
    |> Multi.delete(:event_ban, ban)
    |> Multi.insert(
      :session_activity,
      SessionActivity.changeset(%SessionActivity{}, session_activity)
    )
    |> Repo.transaction()
  end

  def user_banned(user_id, event_id) do
    query =
      from(b in EventBan,
        where: b.event_id == ^event_id and b.user_id == ^user_id
      )

    query
    |> Repo.one()
  end

  def banned_users(event_id) do
    query =
      from(b in EventBan,
        where: b.event_id == ^event_id
      )

    query
    |> Repo.all()
  end

  def list_session_activities(session) do
    query =
      from(s in SessionActivity,
        where: s.session_id == ^session.id,
        preload: [:user],
        order_by: s.inserted_at
      )

    query
    |> Repo.all()
    |> Enum.map(fn activity ->
      %{
        activity
        | inserted_at: Timex.to_datetime(activity.inserted_at, session.event.timezone)
      }
    end)
  end

  def correct_timezone(map, field, event) do
    Map.update!(map, field, &Timex.to_datetime(&1, event.timezone))
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  def update_event(%Event{} = event, attrs, callback) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
    |> callback(callback)
  end

  @doc """
  Deletes a event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{source: %Event{}}

  """
  def change_event(%Event{} = event) do
    Event.changeset(event, %{})
  end

  alias Noodl.Events.Session

  @doc """
  Returns the list of sessions.

  ## Examples

      iex> list_sessions()
      [%Session{}, ...]

  """
  def list_sessions do
    query = from(session in Session)

    Repo.all(query)
  end

  @doc """
  Gets a single session.

  Raises `Ecto.NoResultsError` if the Session does not exist.

  ## Examples

      iex> get_session!(123)
      %Session{}

      iex> get_session!(456)
      ** (Ecto.NoResultsError)

  """
  def get_session!(id), do: Repo.get!(Session, id)

  @doc """
  Gets a single session by various fields

  Raises `Ecto.NoResultsError` if the Session does not exist.

  ## Examples

      iex> get_session_by!(slug: "123", [:foo, :bar])
      %Session{}

      iex> get_session_by!(slug: "no no")
      ** (Ecto.NoResultsError)

  """
  def get_session_by!(params, preloads \\ []),
    do: Repo.get_by!(Session, params) |> Repo.preload(preloads)

  def get_session_by(params, preloads \\ []) do
    case Repo.get_by(Session, params) do
      nil -> {:error, :not_found}
      session -> {:ok, session |> Repo.preload(preloads)}
    end
  end

  @doc """
  Creates a session.

  ## Examples

      iex> create_session(%Session{}, %{field: value})
      {:ok, %Session{}}

      iex> create_session(%Session{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_session(session, event, attrs) do
    Multi.new()
    |> Multi.insert(
      :session,
      session
      |> Session.changeset(event, attrs)
    )
    |> Repo.transaction()
  end

  @doc """
  Updates a session.

  ## Examples

      iex> update_session(session, %{field: new_value})
      {:ok, %Session{}}

      iex> update_session(session, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_session(%Session{} = session, event, attrs) do
    session
    |> Session.changeset(event, attrs)
    |> Repo.update()
  end

  def update_session_with_activity(%Session{} = session, event, attrs, session_activity) do
    Multi.new()
    |> Multi.update(:session, Session.changeset(session, event, attrs))
    |> Multi.insert(
      :session_activity,
      SessionActivity.changeset(%SessionActivity{}, session_activity)
    )
    |> Repo.transaction()
  end

  @doc """
  Deletes a session.

  ## Examples

      iex> delete_session(session)
      {:ok, %Session{}}

      iex> delete_session(session)
      {:error, %Ecto.Changeset{}}

  """
  def delete_session(%Session{} = session) do
    Repo.delete(session)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking session changes.

  ## Examples

      iex> change_session(session)
      %Ecto.Changeset{source: %Session{}}

  """
  def change_session(%Session{} = session, event) do
    Session.changeset(session, event, %{})
  end

  def list_sessions_for_event(event, preloads \\ []) do
    query =
      from(session in Session,
        where: session.event_id == ^event.id,
        order_by: session.start_datetime
      )

    query
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def active_sessions_for_event(event) do
    query =
      from(session in Session,
        where: session.event_id == ^event.id and not (session.status == "ended"),
        order_by: session.start_datetime
      )

    query
    |> Repo.all()
  end

  def sessions_by_day(sessions, event) do
    sessions
    |> Enum.group_by(fn session ->
      Timex.to_datetime(session.start_datetime, event.timezone)
      |> DateTime.to_date()
    end)
    |> Enum.into([], fn {key, list} ->
      {key, Enum.sort_by(list, &Timex.to_datetime(&1.start_datetime, event.timezone), Date)}
    end)
    |> Enum.sort_by(
      fn {date, _sessions} ->
        date
      end,
      Date
    )
  end

  alias Noodl.Events.Proposal

  @doc """
  Returns the list of proposals.

  ## Examples

      iex> list_proposals()
      [%Proposal{}, ...]

  """
  def list_proposals do
    Repo.all(Proposal)
  end

  @doc """
  Returns the list of proposals for an event.

  ## Examples

      iex> list_proposals(%Event{})
      [%Proposal{}, ...]

  """
  def list_pending_proposals_for_event(event) do
    from(proposal in Proposal,
      where: proposal.event_id == ^event.id and is_nil(proposal.approved)
    )
    |> Repo.all()
  end

  def list_proposals_for_event(event, preloads \\ [:session, :user]) do
    from(proposal in Proposal,
      where: proposal.event_id == ^event.id,
      left_join: session in assoc(proposal, :session),
      preload: ^preloads,
      distinct: true
    )
    |> Repo.all()
  end

  @doc """
  Gets a single proposal.

  Raises `Ecto.NoResultsError` if the Proposal does not exist.

  ## Examples

      iex> get_proposal!(123)
      %Proposal{}

      iex> get_proposal!(456)
      ** (Ecto.NoResultsError)

  """
  def get_proposal!(id), do: Repo.get!(Proposal, id)

  @doc """
  Creates a proposal.

  ## Examples

      iex> create_proposal(%Proposal{}, %{field: value})
      {:ok, %Proposal{}}

      iex> create_proposal(%Proposal{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_proposal(proposal, attrs) do
    proposal
    |> Proposal.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a proposal.

  ## Examples

      iex> update_proposal(proposal, %{field: new_value})
      {:ok, %Proposal{}}

      iex> update_proposal(proposal, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_proposal(%Proposal{} = proposal, attrs) do
    proposal
    |> Proposal.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a proposal.

  ## Examples

      iex> delete_proposal(proposal)
      {:ok, %Proposal{}}

      iex> delete_proposal(proposal)
      {:error, %Ecto.Changeset{}}

  """
  def delete_proposal(%Proposal{} = proposal) do
    Repo.delete(proposal)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking proposal changes.

  ## Examples

      iex> change_proposal(proposal)
      %Ecto.Changeset{source: %Proposal{}}

  """
  def change_proposal(%Proposal{} = proposal) do
    Proposal.changeset(proposal, %{})
  end

  @doc ~S"""
  Approves or denies a proposal

  ## Examples

      iex> approve_or_deny_proposal(proposal, "yes")
      %Proposal{approved: true}
  """
  def approve_or_deny_proposal(proposal, "yes"), do: approve_or_deny_proposal(proposal, true)
  def approve_or_deny_proposal(proposal, "no"), do: approve_or_deny_proposal(proposal, false)

  def approve_or_deny_proposal(proposal, approval) do
    proposal
    |> Proposal.changeset(%{approved: approval})
    |> Repo.update()
  end

  def get_sessions_by_event(event_id, preloads \\ [:host]) do
    query =
      from(s in Session,
        where: s.event_id == ^event_id,
        preload: ^preloads,
        select: s
      )

    Repo.all(query)
  end

  def list_events_by_search(search, limit, offset, params \\ %{}) do
    topic = params[:topic]
    language = params[:language]
    timezone = params[:timezone]

    now = Timex.now()

    query =
      from(e in Event,
        where: e.is_live and e.end_datetime > ^now,
        preload: [:releases],
        order_by: [desc: e.start_datetime],
        limit: ^limit,
        offset: ^offset
      )

    query =
      if not is_nil(search) and search != "" do
        query |> where([event], ilike(event.name, ^"%#{search}%"))
      else
        query
      end

    query =
      if not is_nil(topic) and topic != "" do
        query |> where([event], event.topic == ^topic)
      else
        query
      end

    query =
      if not is_nil(language) and language != "" do
        query |> where([event], event.language == ^language)
      else
        query
      end

    query =
      if not is_nil(timezone) and timezone != "" do
        query |> where([event], event.timezone == ^timezone)
      else
        query
      end

    Repo.all(query)
  end

  def get_created_events(user_id) do
    now = NaiveDateTime.utc_now()

    query =
      from(e in Event,
        left_join: user_roles in assoc(e, :user_roles),
        on: user_roles.user_id == ^user_id,
        left_join: role in assoc(user_roles, :role),
        preload: [user_roles: {user_roles, [role: role]}],
        where: e.creator_id == ^user_id and e.end_datetime > ^now
      )

    Repo.all(query)
  end

  def get_expired_events(user_id) do
    now = NaiveDateTime.utc_now()

    query =
      from(e in Event,
        where: e.creator_id == ^user_id and e.end_datetime < ^now
      )

    Repo.all(query)
  end

  def session_channel_name(session), do: "session:#{session.id}"

  def stream_channel_details(session, user \\ %{}) do
    channel = session_channel_name(session)
    Phoenix.PubSub.subscribe(Noodl.PubSub, channel)

    %{
      channel: channel,
      message: %Message{user_id: Map.get(user, :id), session_id: session.id}
    }
  end

  alias Noodl.Events.Recording

  @doc """
  Returns the list of recordings.

  ## Examples

      iex> list_recordings()
      [%Recording{}, ...]

  """
  def list_recordings do
    Repo.all(Recording)
  end

  @doc """
  Gets a single recording.

  Raises `Ecto.NoResultsError` if the Recording does not exist.

  ## Examples

      iex> get_recording!(123)
      %Recording{}

      iex> get_recording!(456)
      ** (Ecto.NoResultsError)

  """
  def get_recording!(id), do: Repo.get!(Recording, id)

  def get_recording_by(fields, preloads \\ []) do
    case Repo.get_by(Recording, fields) do
      nil ->
        {:error, :not_found}

      model ->
        {:ok,
         model
         |> Repo.preload(preloads)}
    end
  end

  @doc """
  Creates a recording.

  ## Examples

      iex> create_recording(%{field: value})
      {:ok, %Recording{}}

      iex> create_recording(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_recording(%Recording{} = recording, attrs \\ %{}) do
    recording
    |> Recording.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a recording.

  ## Examples

      iex> update_recording(recording, %{field: new_value})
      {:ok, %Recording{}}

      iex> update_recording(recording, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_recording(%Recording{} = recording, attrs) do
    recording
    |> Recording.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a recording.

  ## Examples

      iex> delete_recording(recording)
      {:ok, %Recording{}}

      iex> delete_recording(recording)
      {:error, %Ecto.Changeset{}}

  """
  def delete_recording(%Recording{} = recording) do
    Repo.delete(recording)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking recording changes.

  ## Examples

      iex> change_recording(recording)
      %Ecto.Changeset{data: %Recording{}}

  """
  def change_recording(%Recording{} = recording, attrs \\ %{}) do
    Recording.changeset(recording, attrs)
  end

  def list_sessions_about_to_start(interval) do
    now = Timex.now()
    time_from_now = now |> Timex.shift(minutes: interval)

    query =
      from(event in Event,
        left_join: session in assoc(event, :sessions),
        left_join: tickets in assoc(event, :tickets),
        left_join: user in assoc(tickets, :user),
        left_join: push_subscription in assoc(user, :push_subscription),
        left_join: subscription in Accounts.Subscription,
        on:
          subscription.user_id == user.id and
            subscription.type in ["session_start", "event_start"],
        where:
          event.is_live and
            session.start_datetime > ^now and
            session.start_datetime <= ^time_from_now and
            (is_nil(subscription) or not subscription.unsubscribed),
        select: %{
          name: event.name,
          session: session.name,
          user: %{
            email: user.email,
            push_subscription: push_subscription
          }
        }
      )

    Repo.all(query)
  end

  @doc """
  Returns the list of sponsors.

  ## Examples

      iex> list_sponsors()
      [%Sponsor{}, ...]

  """
  def list_sponsors_by_event(event_id) do
    query =
      from(s in Sponsor,
        where: s.event_id == ^event_id
      )

    Repo.all(query)
  end

  @doc """
  Gets a single sponsor.

  Raises `Ecto.NoResultsError` if the Sponsor does not exist.

  ## Examples

      iex> get_sponsor!(123)
      %Sponsor{}

      iex> get_sponsor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sponsor!(id), do: Repo.get!(Sponsor, id)

  @doc """
  Creates a sponsor.

  ## Examples

      iex> create_sponsor(%{field: value})
      {:ok, %Sponsor{}}

      iex> create_sponsor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_sponsor(%Sponsor{} = sponsor, attrs, callback) do
    sponsor
    |> Sponsor.changeset(attrs)
    |> Repo.insert()
    |> callback(callback)
  end

  def update_sponsor_photo(sponsor, path, entry) do
    sponsor |> change_sponsor() |> Image.add_file(:image, path, entry) |> Repo.update()
  end

  @doc """
  Updates a sponsor.

  ## Examples

      iex> update_sponsor(sponsor, %{field: new_value})
      {:ok, %Sponsor{}}

      iex> update_sponsor(sponsor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sponsor(%Sponsor{} = sponsor, attrs, callback) do
    sponsor
    |> Sponsor.changeset(attrs)
    |> Repo.update()
    |> callback(callback)
  end

  @doc """
  Deletes a sponsor.

  ## Examples

      iex> delete_sponsor(sponsor)
      {:ok, %Sponsor{}}

      iex> delete_sponsor(sponsor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sponsor(%Sponsor{} = sponsor) do
    Repo.delete(sponsor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sponsor changes.

  ## Examples

      iex> change_sponsor(sponsor)
      %Ecto.Changeset{source: %Sponsor{}}

  """
  def change_sponsor(%Sponsor{} = sponsor) do
    Sponsor.changeset(sponsor, %{})
  end

  def has_host_abilities?(%{sessions: sessions}, user) do
    host = sessions |> Enum.find(fn s -> s.host_id == user.id end)

    not is_nil(host)
  end

  def has_viewer_abilities?(session, event, user) do
    user_tickets = Ticketing.get_user_active_tickets(session.event.id, user.id)

    not Enum.empty?(user_tickets) or is_organizer?(user, event) or
      is_creator?(user, event) or has_host_abilities?(event, user)
  end

  @doc """
  Used for informing a user all the possible crap that is wrong with their event
  so they can fix it. Right now only checks session start/end, release start/end, and
  counts invalid tickets.
  """
  def validate_event(%{is_live: true}),
    do: %{
      sessions: [],
      releases: 0,
      tickets: 0
    }

  def validate_event(event) do
    # Get all the sessions that have start/end times outside the bounds of the event
    invalid_sessions =
      from(session in Session,
        where:
          session.event_id == ^event.id and
            (session.start_datetime < ^event.start_datetime or
               session.end_datetime > ^event.end_datetime),
        select: %{slug: session.slug, name: session.name}
      )

    # Get all the releases that have start/end times outside the bounds of the event
    # I don't think we have a way in the UI currently to fix these
    invalid_releases =
      from(release in Ticketing.Release,
        where:
          release.event_id == ^event.id and
            (release.start_at < ^event.start_datetime or
               release.end_at > ^event.end_datetime),
        select: count(release)
      )

    # Get the number of tickets that will be auto updated to fit inside the exp start/end
    tickets_to_update =
      from(ticket in Ticketing.Ticket,
        # for now the expires at should be equal to the end datetime
        where: ticket.event_id == ^event.id and ticket.expires_at != ^event.end_datetime,
        select: count(ticket)
      )

    %{
      sessions: Repo.all(invalid_sessions),
      releases: Repo.one(invalid_releases),
      tickets: Repo.one(tickets_to_update)
    }
  end

  def publish_event(event) do
    Multi.new()
    |> Multi.run(:event, fn _repo, _changes ->
      update_event(event, %{"is_live" => true})
    end)
    |> Multi.update_all(
      :releases,
      from(release in Ticketing.Release,
        where:
          release.event_id == ^event.id and
            (release.start_at < ^event.start_datetime or
               release.end_at > ^event.end_datetime)
      ),
      # In the future this may or may not need to be more complex
      set: [start_at: event.start_datetime, end_at: event.end_datetime]
    )
    |> Multi.update_all(
      :tickets,
      from(ticket in Ticketing.Ticket,
        where: ticket.event_id == ^event.id and ticket.expires_at != ^event.end_datetime
      ),
      # In the future this may or may not need to be more complex
      set: [expires_at: event.end_datetime]
    )
    |> Repo.transaction()
  end

  def list_recordings_for_event(event, preloads \\ []) do
    query =
      from(recording in Recording,
        join: session in assoc(recording, :session),
        join: event in assoc(session, :event),
        where: event.id == ^event.id
      )

    query |> Repo.all() |> Repo.preload(preloads)
  end

  @cdn Application.get_env(:waffle, :asset_host, "")

  def recording_url(recording) do
    "#{@cdn}/recordings/#{String.replace(recording.session_id, "-", "")}/#{recording.external_id}_session:#{
      recording.session_id
    }.m3u8"
  end

  def download_path(recording) do
    "recordings/#{String.replace(recording.session_id, "-", "")}/#{recording.external_id}_session:#{
      recording.session_id
    }.mp4"
  end

  def weekly_summary() do
    now = Timex.now()
    time_from_now = Timex.shift(now, weeks: 1)

    query =
      from(event in Event,
        where:
          event.is_live and
            event.start_datetime > ^now and
            event.start_datetime <= ^time_from_now
      )

    case Repo.all(query) do
      [] ->
        nil

      events ->
        Accounts.list_confirmed_users()
        |> Enum.map(fn user ->
          message = Email.weekly_summary(user, events)

          Mailer.send_now(user.email, "new_events", message)
        end)
    end
  end

  @animals ~w(
    Dog
    Puppy
    Turtle
    Rabbit
    Parrot
    Cat
    Kitten
    Goldfish
    Mouse
    Fish
    Hamster
    Cow
    Duck
    Shrimp
    Pig
    Goat
    Crab
    Deer
    Bee
    Sheep
    Turkey
    Dove
    Chicken
    Horse
  )

  @adjectives ~w(
    Defiant
    Adorable
    Delightful
    Homely
    Quaint
    Adventurous
    Determined
    Hungry
    Real
    Agreeable
    Different
    Relieved
    Alive
    Rich
    Amused
    Distinct
    Important
    Dizzy
    Innocent
    Shiny
    Inquisitive
    Silly
    Sleepy
    Attractive
    Eager
    Smiling
    Average
    Easy
    Elated
    Jolly
    Elegant
    Joyous
    Sparkling
    Splendid
    Beautiful
    Enchanting
    Kind
    Spotless
    Encouraging
    Stormy
    Bewildered
    Energetic
    Enthusiastic
    Light
    Lively
    Successful
    Super
    Excited
    Lovely
    Talented
    Exuberant
    Lucky
    Tame
    Brainy
    Brave
    Magnificent
    Faithful
    Misty
    Bright
    Modern
    Fancy
    Thankful
    Fantastic
    Thoughtful
    Calm
    Mushy
    Careful
    Mysterious
    Cautious
    Fine
    Tough
    Charming
    Foolish
    Cheerful
    Nutty
    Clumsy
    Funny
    Unusual
    Gentle
    Comfortable
    Gifted
    Glamorous
    Gleaming
    Outrageous
    Victorious
    Glorious
    Outstanding
    Vivacious
    Cooperative
    Good
    Courageous
    Gorgeous
    Graceful
    Perfect
    Pleasant
    Grumpy
    Wild
    Curious
    Witty
    Handsome
    Powerful
    Happy
    Precious
    Prickly
    Zany
    Hilarious
    Zealous
  )
  def generate_anonymous_user() do
    uid = UUID.uuid4()

    %{
      email: "none",
      firstname: Enum.random(@adjectives),
      lastname: Enum.random(@animals),
      id: uid,
      role: :spectator,
      recording_id: "0"
    }
  end

  alias NoodlWeb.Presence

  @doc """
  Given a session, check if the number of spectators is set and
  that the current number of users is less than the max_spectators.
  """
  def session_at_capacity?(session) do
    users =
      session
      |> session_channel_name()
      |> Presence.get_users()
      |> Enum.filter(&(&1.role == :spectator))

    session.spectators and not is_nil(session.max_spectators) and
      Enum.count(users) >= session.max_spectators
  end

  def track_user(user, role, channel_name) do
    user =
      Map.take(user, [
        :email,
        :firstname,
        :lastname,
        :id,
        :profile_photo,
        :social_username,
        :recording_id
      ])

    Presence.track(
      self(),
      channel_name,
      user.id,
      Map.put(user, :role, role)
    )
  end

  def appropriate_timezone(time, tz), do: appropriate_timezone(time, tz, tz)

  def appropriate_timezone(time, tz, desired_tz) do
    zone = Timex.Timezone.get(tz)

    %{
      time
      | time_zone: zone.full_name,
        zone_abbr: zone.abbreviation,
        # This is for DST, remove it because we don't care about dst offset here
        # std_offset: zone.offset_std,
        utc_offset: zone.offset_utc
    }
    |> Timex.to_datetime(desired_tz)
  end
end
