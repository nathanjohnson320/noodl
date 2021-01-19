defmodule NoodlWeb.Live.Pages.TermsAndConditions do
  @moduledoc """
  Terms and Conditions LiveView
  """

  use NoodlWeb, :live_view

  def mount(_params, params, socket) do
    {:ok, socket |> Authentication.assign_user(params)}
  end
end
