defmodule EventSummary do
  use Phoenix.LiveComponent

  alias Noodl.{Accounts, Events}

  def preload(assigns) do
    assigns
    |> Enum.map(fn %{session: %{event_id: event_id}} = assigns ->
      event =
        Events.get_event_by!([id: event_id], [
          :sessions,
          :sponsors
        ])

      speakers = Accounts.list_event_members_with_roles([:speaker], event)

      assigns
      |> Map.put(:event, event)
      |> Map.put(:speakers, speakers)
      |> Map.put(:current_tab, "schedule")
      |> Map.put(:tabs, ["about", "schedule", "speakers", "sponsors"])
      |> Map.put(:sessions, Events.sessions_by_day(event.sessions, event))
    end)
  end

  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, socket |> assign(current_tab: tab)}
  end

  def tab_selected(%{current_tab: selected}, tab) when selected == tab, do: "bg-red-200"
  def tab_selected(_assigns, _tab), do: ""

  defdelegate sponsor_photo_url(user), to: NoodlWeb.SponsorsView
  defdelegate gravatar_url(user), to: NoodlWeb.AccountsView
  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
end
