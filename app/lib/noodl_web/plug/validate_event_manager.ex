defmodule NoodlWeb.Plug.ValidateEventManager do
  @moduledoc ~S"""
  This plug handles ensuring that a user is in
  the assigns otherwise it forces a redirect.
  """
  import Plug.Conn
  alias NoodlWeb.Router.Helpers, as: Routes

  alias NoodlWeb.Live

  def init(options) do
    options
  end

  def handle_redirect(conn) do
    conn
    |> Phoenix.Controller.put_flash(:error, "Sorry, you don't have access to view this page.")
    |> Phoenix.Controller.redirect(to: Routes.live_path(conn, Live.Pages.Index))
    |> halt()
  end

  def call(%{params: %{"id" => _event_slug}, assigns: %{user: _user}} = conn, _), do: conn
  def call(conn, _), do: handle_redirect(conn)
end
