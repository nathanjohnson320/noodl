defmodule Noodl.Ticketing do
  import Ecto.Query

  alias Ecto.Multi
  alias Noodl.Repo
  alias Ecto.Multi

  alias Noodl.Events.Event
  alias Noodl.Ticketing.Release
  alias Noodl.Ticketing.Ticket
  alias Noodl.Ticketing

  use Timex

  @payout_percent 0.65
  @currency Application.get_env(:money, :default_currency) |> to_string()

  @doc """
  Returns the list of releases.

  ## Examples

      iex> list_releases()
      [%Release{}, ...]

  """
  def list_releases do
    Repo.all(Release)
  end

  def list_releases_for_event(event) do
    from(release in Release,
      where: release.event_id == ^event.id
    )
    |> Repo.all()
  end

  @doc """
  Gets a single release.

  Raises `Ecto.NoResultsError` if the Release does not exist.

  ## Examples

      iex> get_release!(123)
      %Release{}

      iex> get_release!(456)
      ** (Ecto.NoResultsError)

  """
  def get_release!(id, preloads \\ []), do: Repo.get!(Release, id) |> Repo.preload(preloads)

  @doc """
  Creates a release.

  ## Examples

      iex> create_release(%Release{}, %{field: value})
      {:ok, %Release{}}

      iex> create_release(%Release{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_release(%Release{} = release, attrs) do
    release
    |> Release.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a release.

  ## Examples

      iex> update_release(release, %{field: new_value})
      {:ok, %Release{}}

      iex> update_release(release, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_release(release, attrs) do
    Multi.new()
    |> Multi.insert_or_update(
      :release,
      release
      |> Release.changeset(attrs)
    )
    |> Repo.transaction()
  end

  @doc """
  Deletes a release.

  ## Examples

      iex> delete_release(release)
      {:ok, %Release{}}

      iex> delete_release(release)
      {:error, %Ecto.Changeset{}}

  """
  def delete_release(%Release{} = release) do
    Repo.delete(release)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking release changes.

  ## Examples

      iex> change_release(release)
      %Ecto.Changeset{source: %Release{}}

  """
  def change_release(%Release{} = release) do
    Release.changeset(release, %{})
  end

  alias Noodl.Ticketing.Ticket

  @doc """
  Returns the list of tickets.

  ## Examples

      iex> list_tickets()
      [%Ticket{}, ...]

  """
  def list_tickets do
    Repo.all(Ticket)
  end

  @doc """
  Gets a single ticket.

  Raises `Ecto.NoResultsError` if the Ticket does not exist.

  ## Examples

      iex> get_ticket!(123)
      %Ticket{}

      iex> get_ticket!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ticket!(id, preloads \\ []), do: Ticket |> Repo.get!(id) |> Repo.preload(preloads)

  def get_ticket_by(params, preloads \\ []) do
    case Ticket |> Repo.get_by(params) do
      nil ->
        {:error, :not_found}

      ticket ->
        {:ok, ticket |> Repo.preload(preloads)}
    end
  end

  @doc """
  Creates a ticket.

  ## Examples

      iex> create_ticket%(%Ticket{}, %{field: value})
      {:ok, %Ticket{}}

      iex> create_ticket(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ticket(ticket, attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ticket.

  ## Examples

      iex> update_ticket(ticket, %{field: new_value})
      {:ok, %Ticket{}}

      iex> update_ticket(ticket, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ticket(%Ticket{} = ticket, attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ticket.

  ## Examples

      iex> delete_ticket(ticket)
      {:ok, %Ticket{}}

      iex> delete_ticket(ticket)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ticket(%Ticket{} = ticket) do
    Repo.delete(ticket)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ticket changes.

  ## Examples

      iex> change_ticket(ticket)
      %Ecto.Changeset{source: %Ticket{}}

  """
  def change_ticket(%Ticket{} = ticket) do
    Ticket.changeset(ticket, %{})
  end

  alias Noodl.Ticketing.Refund

  @doc """
  Returns the list of refunds.

  ## Examples

      iex> list_refunds()
      [%Refund{}, ...]

  """
  def list_refunds do
    Repo.all(Refund)
  end

  @doc """
  Gets a single refund.

  Raises `Ecto.NoResultsError` if the Refund does not exist.

  ## Examples

      iex> get_refund!(123)
      %Refund{}

      iex> get_refund!(456)
      ** (Ecto.NoResultsError)

  """
  def get_refund!(id), do: Repo.get!(Refund, id)

  @doc """
  Creates a refund.

  ## Examples

      iex> create_refund(%{field: value})
      {:ok, %Refund{}}

      iex> create_refund(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_refund(attrs \\ %{}) do
    %Refund{}
    |> Refund.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a refund.

  ## Examples

      iex> update_refund(refund, %{field: new_value})
      {:ok, %Refund{}}

      iex> update_refund(refund, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_refund(%Refund{} = refund, attrs) do
    refund
    |> Refund.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a refund.

  ## Examples

      iex> delete_refund(refund)
      {:ok, %Refund{}}

      iex> delete_refund(refund)
      {:error, %Ecto.Changeset{}}

  """
  def delete_refund(%Refund{} = refund) do
    Repo.delete(refund)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking refund changes.

  ## Examples

      iex> change_refund(refund)
      %Ecto.Changeset{source: %Refund{}}

  """
  def change_refund(%Refund{} = refund) do
    Refund.changeset(refund, %{})
  end

  def get_amount_tickets_sold(event_id) do
    now = NaiveDateTime.utc_now()

    query =
      from(t in Ticket,
        select: count(t.id),
        where:
          t.event_id == ^event_id and t.expires_at > ^now and t.paid and
            not t.admin
      )

    Repo.all(query)
  end

  def get_user_active_tickets(event_id, user_id, preload \\ []) do
    now = NaiveDateTime.utc_now()

    query =
      from(t in Ticket,
        where:
          t.event_id == ^event_id and t.user_id == ^user_id and t.expires_at > ^now and
            t.paid,
        preload: ^preload
      )

    Repo.all(query)
  end

  def get_user_future_events(user_id) do
    now = NaiveDateTime.utc_now()

    query =
      from(t in Ticket,
        join: e in assoc(t, :event),
        left_join: user_roles in assoc(e, :user_roles),
        on: user_roles.user_id == ^user_id,
        left_join: role in assoc(user_roles, :role),
        preload: [event: {e, user_roles: {user_roles, [role: role]}}],
        where: t.user_id == ^user_id and t.expires_at > ^now and t.paid and not t.admin,
        distinct: t.event_id
      )

    Repo.all(query)
  end

  def get_user_recent_tickets(user_id) do
    now = NaiveDateTime.utc_now()
    three_months_ago = now |> Timex.subtract(Duration.from_days(90))

    query =
      from(t in Ticket,
        where:
          t.user_id == ^user_id and t.inserted_at > ^three_months_ago and t.inserted_at < ^now,
        preload: [:release, :event],
        order_by: t.inserted_at,
        limit: 4
      )

    Repo.all(query)
  end

  def get_user_recent_events(user_id) do
    now = NaiveDateTime.utc_now()

    query =
      from(t in Ticket,
        where: t.user_id == ^user_id and ^now > t.expires_at and not is_nil(t.redeemed_at),
        preload: [:event],
        distinct: t.event_id,
        order_by: t.inserted_at
      )

    Repo.all(query)
  end

  def can_purchase_ticket?(user, release) do
    now = NaiveDateTime.utc_now()

    [amt_sold] = get_amount_tickets_sold(release.event_id)

    user_tickets =
      get_user_active_tickets(release.event_id, user.id)
      |> Enum.count()

    amt_sold < release.quantity and
      user_tickets < release.max_tickets_per_person and
      Timex.before?(now, release.event.end_datetime)
  end

  def has_tickets?(event, user) do
    sessions =
      event
      |> Noodl.Events.list_sessions_for_event()

    user_tickets = get_user_active_tickets(event.id, user.id)

    found_host = Enum.find(sessions, fn s -> s.host_id == Map.get(user || %{}, :id) end)

    not Enum.empty?(user_tickets) or not is_nil(found_host)
  end

  def cleanup_release_quantities(releases) do
    for {id, quantity} <- releases,
        quantity |> Integer.parse() |> elem(0) > 0,
        into: %{},
        do: {id, quantity |> Integer.parse() |> elem(0)}
  end

  def event_ticket_count(event_id) do
    query =
      from(release in Release,
        join: ticket in assoc(release, :tickets),
        join: user in assoc(ticket, :user),
        where: release.event_id == ^event_id and ticket.paid,
        group_by: user.id,
        select: count(user.id, :distinct)
      )

    Repo.all(query) |> Enum.count()
  end

  def get_releases(releases) do
    release_ids = for {id, _quantity} <- releases, do: id

    query =
      from(release in Release,
        join: event in assoc(release, :event),
        preload: [event: event],
        where: release.id in ^release_ids
      )

    query
    |> Repo.all()
    |> Enum.map(fn release ->
      Map.put(release, :purchase_quantity, releases[release.id])
    end)
  end

  def get_ticket_total(releases) do
    releases
    |> Enum.reduce(Money.new(0), fn release, acc ->
      Money.add(acc, Money.multiply(release.price, release.purchase_quantity))
    end)
  end

  def payout() do
    # get all the unpaid events that are >= 1 day after end_date
    # and have sold tickets
    # and have creators with stripe accounts
    now = NaiveDateTime.utc_now() |> Timex.shift(days: -1)

    query =
      from(event in Event,
        join: creator in assoc(event, :creator),
        join: ticket in assoc(event, :tickets),
        preload: [creator: creator],
        group_by: [event.id, creator.id],
        having: count(ticket) > 0,
        where:
          event.end_datetime <= ^now and not event.paid_out and
            not is_nil(creator.stripe_account) and
            ticket.paid and
            not is_nil(ticket.price_paid) and
            not ticket.admin
      )

    query
    |> Repo.all()
    |> Enum.each(fn event ->
      Multi.new()
      |> Multi.run(:initiate_transfer, fn _repo, _changes ->
        # They get 70% of non refunded ticket sales
        total = Money.multiply(total_earned(event.id), @payout_percent)

        {:ok, _tx} =
          Stripe.Transfer.create(%{
            amount: total.amount,
            currency: @currency,
            destination: event.creator.stripe_account
          })
      end)
      |> Multi.insert(:event, Event.changeset(event, %{paid_out: true}))
      |> Repo.transaction()
    end)
  end

  def tickets_sales_from_date(event, start_date) do
    query =
      from(release in Release,
        join: ticket in assoc(release, :tickets),
        where:
          release.event_id == ^event.id and
            ^start_date >=
              ticket.inserted_at,
        group_by: fragment("date(?)", ticket.inserted_at),
        select: %{
          y: count(ticket),
          t: fragment("date(?)", ticket.inserted_at)
        }
      )

    Repo.all(query)
  end

  def total_earned(event) do
    query =
      from(release in Release,
        join: ticket in assoc(release, :tickets),
        left_join: refund in assoc(ticket, :refund),
        where: release.event_id == ^event.id and is_nil(refund),
        select: sum(ticket.price_paid)
      )

    Repo.one(query) || Money.new(0)
  end

  def unique_ticket_purchasers(event) do
    query =
      from(release in Release,
        join: ticket in assoc(release, :tickets),
        join: user in assoc(ticket, :user),
        where: release.event_id == ^event.id,
        group_by: user.id,
        distinct: true,
        select: count(user.id)
      )

    Repo.one(query)
  end

  def event_members(event) do
    from(user in Noodl.Accounts.User,
      join: ticket in assoc(user, :tickets),
      as: :ticket,
      left_join: user_role in assoc(user, :user_roles),
      as: :user_role,
      left_join: role in assoc(user_role, :role),
      as: :role,
      where:
        (is_nil(user_role) or user_role.event_id == ^event.id) and
          ticket.event_id == ^event.id
    )
  end

  def list_event_members(event) do
    event
    |> event_members()
    |> preload([ticket: ticket, user_role: user_role, role: role],
      tickets: ticket,
      user_roles: {user_role, [role: role]}
    )
    |> Repo.all()
  end

  def create_admin_ticket(event, user_id) do
    change_ticket(%Ticketing.Ticket{
      user_id: user_id,
      release_id: nil,
      event_id: event.id,
      code: UUID.uuid4(),
      expires_at: event.end_datetime,
      name: "Admin Ticket",
      paid: true,
      admin: true
    })
  end

  def admin_tickets(event, user_id) do
    from(ticket in Ticket,
      where:
        ticket.user_id == ^user_id and ticket.admin and
          ticket.event_id == ^event.id
    )
  end
end
