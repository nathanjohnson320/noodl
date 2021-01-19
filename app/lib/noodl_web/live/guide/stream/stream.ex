defmodule NoodlWeb.Live.Guide.Stream do
  @moduledoc ~S"""
  LiveView for the guide stream page
  """
  use NoodlWeb, :live_view

  def mount(_params, session, socket) do
    {:ok, socket |> Authentication.assign_user(session)}
  end
end
