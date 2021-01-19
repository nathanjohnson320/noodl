defmodule NoodlWeb.Live.Events.Members do
  @moduledoc ~S"""
  LiveView for the member show page.
  """
  use NoodlWeb, :live_view

  alias Noodl.{Events, Ticketing}
  alias NoodlWeb.{SharedView, AccountsView}

  def mount(%{"id" => id}, session, socket) do
    event = Events.get_event_by!(slug: id)
    members = Ticketing.list_event_members(event)

    {:ok,
     socket
     |> Authentication.assign_user(session)
     |> assign(
       total_members: Enum.count(members),
       members: members,
       event: event
     )}
  end

  def user_tickets(user) do
    user.tickets |> Enum.map(& &1.release.title) |> Enum.uniq() |> Enum.join(", ")
  end

  defdelegate profile_photo_url(a), to: AccountsView
  defdelegate get_username(a), to: SharedView
  defdelegate user_since(a), to: AccountsView
end
