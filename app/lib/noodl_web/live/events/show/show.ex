defmodule NoodlWeb.Live.Events.Show do
  @moduledoc ~S"""
  LiveView for the events show page
  """
  use NoodlWeb, :live_view

  alias Noodl.{Accounts, Events, Meta, Ticketing}
  alias Noodl.Ticketing.{Cart, Ticket}
  alias NoodlWeb.{EventsView, LayoutView}

  @status_ended "ended"

  def mount(%{"id" => id}, session, socket) do
    %{assigns: %{user: user}} = socket = Authentication.assign_user(socket, session)

    %{sessions: sessions} =
      event =
      Events.get_event_by!(%{slug: id}, [
        :releases,
        :creator,
        :sponsors,
        :sessions
      ])

    members = Ticketing.list_event_members(event)

    user_tickets =
      if is_nil(user) do
        []
      else
        Ticketing.get_user_active_tickets(event.id, user.id)
      end

    {:ok,
     assign(socket,
       user_tickets: user_tickets,
       event: event,
       sessions: sessions |> Events.sessions_by_day(event),
       members: members,
       members_count: Enum.count(members),
       recordings: Events.list_recordings_for_event(event),
       speakers: Accounts.list_event_members_with_roles([:speaker], event),
       cart: %{},
       releases: for(release <- event.releases, into: %{}, do: {release.id, release}),
       meta: %Meta{
         title: event.name,
         description: event.description,
         image: cover_photo_url(event),
         url: LayoutView.full_url(Routes.events_show_path(socket, :show, event.slug))
       }
     )}
  end

  def handle_event(
        "proceed",
        _params,
        %{assigns: %{event: event}} = socket
      ) do
    now = NaiveDateTime.utc_now()

    active_session =
      Enum.find(event.sessions, fn s ->
        Timex.after?(now, s.start_datetime) and Timex.before?(now, s.end_datetime) and
          s.status != @status_ended
      end)

    if active_session do
      {:noreply,
       socket
       |> push_redirect(
         to:
           Routes.events_session_dashboard_path(
             socket,
             :dashboard,
             event.slug,
             active_session.slug
           )
       )}
    else
      {:ok, first_session} = Enum.fetch(event.sessions, 0)

      {:noreply,
       socket
       |> push_redirect(
         to:
           Routes.events_session_dashboard_path(
             socket,
             :dashboard,
             event.slug,
             first_session.slug
           )
       )}
    end
  end

  def handle_event(
        "add_to_cart",
        _params,
        %{assigns: %{user: nil}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "You must log in before continuing to checkout.")
     |> push_redirect(to: Routes.accounts_path(socket, :login))}
  end

  def handle_event(
        "add_to_cart",
        %{"release" => params},
        %{assigns: %{releases: releases, user: user, event: event}} = socket
      ) do
    params = Ticketing.cleanup_release_quantities(params)

    with total when total > 0 <- total(params, releases),
         {:ok, _tickets} <- Cart.add_tickets(user, params) do
      {:noreply,
       socket |> push_redirect(to: Routes.live_path(socket, Live.Ticketing.Release.Checkout))}
    else
      0 ->
        params
        |> Ticketing.get_releases()
        |> Enum.flat_map(fn release ->
          # Create a ticket for each release of the given quantity
          for _i <- Range.new(1, release.purchase_quantity) do
            Ticketing.create_ticket(
              %Ticket{
                user_id: user.id,
                release_id: release.id,
                event_id: release.event_id
              },
              %{
                "code" => UUID.uuid4(),
                "expires_at" => release.event.end_datetime,
                "name" => release.title,
                "paid" => true,
                "price_paid" => release.price
              }
            )
          end
        end)

        {:noreply,
         socket
         |> put_flash(:info, "Free tickets claimed!")
         |> push_redirect(to: Routes.events_show_path(socket, :show, event.slug))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unknown error occurred while adding tickets to cart.")
         |> push_redirect(to: Routes.events_show_path(socket, :show, event.slug))}
    end
  end

  def handle_event(
        "update_cart",
        %{"release" => quantities},
        %{assigns: %{cart: cart}} = socket
      ) do
    quantities = Ticketing.cleanup_release_quantities(quantities)
    {:noreply, socket |> assign(cart: Map.merge(cart, quantities))}
  end

  def does_release_exist?(%{releases: []}), do: false
  def does_release_exist?(%{releases: _release}), do: true

  defp total(cart, releases) do
    Enum.reduce(cart, 0, fn {id, amount}, acc ->
      acc + amount * releases[id].price.amount
    end)
  end

  def event_ended?(%{end_datetime: end_time, timezone: timezone}) do
    now = Timex.now(timezone)

    Timex.after?(now, Timex.to_datetime(end_time, timezone))
  end

  def release_name(release) do
    "release[#{release.id}]"
  end

  def ticket_text(cart, releases) do
    case total(cart, releases) do
      0 -> "Claim Tickets"
      _ -> "Add to Cart"
    end
  end

  defdelegate is_creator?(user, event), to: Events
  defdelegate user_timezone(socket), to: EventsView
  defdelegate pretty_event_date(event, tz), to: EventsView
  defdelegate cover_photo_url(event), to: EventsView
  defdelegate sponsor_photo_url(user), to: NoodlWeb.SponsorsView
  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
  defdelegate gravatar_url(user), to: NoodlWeb.AccountsView
end
