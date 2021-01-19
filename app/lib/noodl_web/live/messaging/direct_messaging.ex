defmodule NoodlWeb.Live.Messaging.DirectMessaging do
  use NoodlWeb, :live_component

  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
  defdelegate get_username(user), to: NoodlWeb.SharedView
end
