defmodule NoodlWeb.PageController do
  use NoodlWeb, :controller

  alias Phoenix.LiveView.Controller
  alias NoodlWeb.Live.Pages

  def index(conn, _params) do
    conn
    |> Controller.live_render(Pages.Index, session: %{"user" => conn.assigns[:user]})
  end

  def calculator(conn, _params) do
    conn
    |> Controller.live_render(Pages.Calculator, session: %{"user" => conn.assigns[:user]})
  end

  def terms_and_conditions(conn, _params) do
    conn
    |> Controller.live_render(Pages.TermsAndConditions, session: %{"user" => conn.assigns[:user]})
  end

  def privacy_policy(conn, _params) do
    conn
    |> Controller.live_render(Pages.PrivacyPolicy, session: %{"user" => conn.assigns[:user]})
  end
end
