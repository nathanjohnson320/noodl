defmodule NoodlWeb.ProposalView do
  use NoodlWeb, :view

  def render_tags(tags) do
    Enum.join(tags, ", ")
  end

  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
  defdelegate pretty_manage_date(event, date), to: NoodlWeb.EventsView
end
