defmodule NoodlWeb.SharedView do
  use NoodlWeb, :view

  def get_username(%{display_name: display_name}) when not is_nil(display_name), do: display_name

  def get_username(%{firstname: firstname, lastname: lastname})
      when not is_nil(firstname) and not is_nil(lastname) do
    "#{firstname} #{lastname}"
  end

  def get_username(_), do: "Anonymous"

  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
end
