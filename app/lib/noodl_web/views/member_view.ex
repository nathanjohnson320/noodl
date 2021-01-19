defmodule NoodlWeb.MemberView do
  use NoodlWeb, :view

  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
end
