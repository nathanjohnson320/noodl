defmodule NoodlWeb.Live.Guide.Index do
  @moduledoc ~S"""
  LiveView for the accounts profile page.
  """
  use NoodlWeb, :live_view

  def mount(_params, session, socket) do
    {:ok, socket |> Authentication.assign_user(session)}
  end
end
