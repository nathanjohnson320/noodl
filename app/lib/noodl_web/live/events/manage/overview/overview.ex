defmodule NoodlWeb.Live.Events.Overview do
  @moduledoc ~S"""
  LiveView for the overview manage event page.
  """
  use NoodlWeb, :live_view

  alias Noodl.{Accounts, Events, Ticketing}
  alias NoodlWeb.EventsView

  def mount(_params, %{"event" => slug, "user" => user}, socket) do
    event =
      Events.get_event_by!(%{slug: slug}, [
        :releases,
        :sessions
      ])

    speakers = Accounts.list_event_members_with_roles([:speaker], event)
    organizers = Accounts.list_event_members_with_roles([:organizer], event)

    open_speaker_applications = event |> Events.list_pending_proposals_for_event() |> Enum.count()

    sales_start = Timex.shift(Timex.now(), weeks: 2)
    ticket_sales = Ticketing.tickets_sales_from_date(event, sales_start)

    total_earned = Ticketing.total_earned(event)

    {:ok,
     assign(socket,
       open_speaker_applications: open_speaker_applications,
       event: event,
       user: user,
       overview_steps: [
         {"Add Organizers and Speakers", not Enum.empty?(organizers) or not Enum.empty?(speakers),
          Routes.live_path(socket, Live.Events.Manage, event.slug, :members)},
         {"Create Tickets", not Enum.empty?(event.releases),
          Routes.live_path(socket, Live.Events.Manage, event.slug, :tickets)},
         {"Create a session", not Enum.empty?(event.sessions),
          Routes.live_path(socket, Live.Events.Manage, event.slug, :schedule)},
         {"Upload event splash image", not is_nil(event.cover_photo),
          Routes.live_path(socket, Live.Events.Manage, event.slug, :details)}
       ],
       ticket_sales: ticket_sales,
       sales_start: sales_start,
       total_earned: total_earned
     )}
  end

  def handle_event(
        "change_status",
        %{"status" => status},
        %{assigns: %{event: event}} = socket
      )
      when status in ["live", "draft"] do
    live = status == "live"
    {:ok, _event} = Events.update_event(event, %{"is_live" => live})

    {:noreply,
     socket
     |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug))}
  end

  def ticket_data(sales) do
    Jason.encode!(sales)
  end

  defdelegate event_setup?(a), to: EventsView
  defdelegate date(a), to: EventsView
end
