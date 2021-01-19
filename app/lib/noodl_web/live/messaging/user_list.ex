defmodule NoodlWeb.Live.Messaging.UserList do
  use NoodlWeb, :live_component

  alias NoodlWeb.Live.Messaging.Chat

  defdelegate is_organizer?(user, organizers), to: Chat
  defdelegate user_banned?(user, banned_users), to: Chat
  defdelegate get_username(user), to: NoodlWeb.SharedView
  defdelegate within_allowed_time?(a, b), to: NoodlWeb.SessionView
end
