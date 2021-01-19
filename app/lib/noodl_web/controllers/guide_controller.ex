defmodule NoodlWeb.GuideController do
  use NoodlWeb, :controller

  alias Phoenix.LiveView.Controller
  alias NoodlWeb.Live.Guide

  def index(conn, _params) do
    conn
    |> Controller.live_render(Guide.Index, session: %{"user" => conn.assigns[:user]})
  end

  def stream(conn, _params) do
    conn
    |> Controller.live_render(Guide.Stream, session: %{"user" => conn.assigns[:user]})
  end
end
