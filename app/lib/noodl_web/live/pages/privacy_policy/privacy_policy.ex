defmodule NoodlWeb.Live.Pages.PrivacyPolicy do
  @moduledoc """
  Privacy Policy LiveView
  """

  use NoodlWeb, :live_view

  def mount(_params, params, socket) do
    {:ok, socket |> Authentication.assign_user(params)}
  end
end
