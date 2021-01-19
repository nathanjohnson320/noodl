defmodule NoodlWeb.Presence do
  @moduledoc ~S"""
  Module handles phoenix presence and utility functions
  for dealing with presence state.
  """
  use Phoenix.Presence,
    otp_app: :team_manager,
    pubsub_server: Noodl.PubSub

  def get_users(channel_name) do
    channel_name
    |> list()
    |> Enum.map(fn {_user_id, %{metas: metas}} ->
      hd(metas)
    end)
  end
end
