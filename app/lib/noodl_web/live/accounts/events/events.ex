defmodule NoodlWeb.Live.Accounts.Events do
  @moduledoc ~S"""
  LiveView for the accounts profile page.
  """
  use NoodlWeb, :live_view

  alias Noodl.{Events, Ticketing}
  alias NoodlWeb.EventsView

  def mount(_params, %{"user" => id} = session, socket) do
    events = Ticketing.get_user_future_events(id)
    current_created_events = Events.get_created_events(id)
    expired_created_events = Events.get_expired_events(id)
    %{assigns: %{user: user}} = socket = Authentication.assign_user(socket, session)

    {:ok,
     socket
     |> assign(
       user: user,
       event_tickets: events,
       current_created_events: current_created_events,
       expired_created_events: expired_created_events
     )}
  end

  def format_event_date(%{redeemed_at: redeemed_at}) do
    case Timex.format(redeemed_at, "%B %d, %Y", :strftime) do
      {:ok, time} -> time
      _ -> ""
    end
  end

  def format_event_start_time(%{start_datetime: start_datetime}, timezone) do
    start_datetime = Timex.to_datetime(start_datetime, timezone)

    case Timex.format(start_datetime, "%l %p %Z", :strftime) do
      {:ok, time} -> "#{Timex.from_now(start_datetime)} at #{time}"
      _ -> ""
    end
  end

  def format_time(time, str) do
    case Timex.format(time, str, :strftime) do
      {:ok, time} -> time
      _ -> ""
    end
  end

  def event_role(_user_id, _) do
    "Creator"
  end

  defdelegate cover_photo_url(event), to: EventsView
  defdelegate user_timezone(socket), to: EventsView
end
