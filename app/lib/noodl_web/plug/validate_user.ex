defmodule NoodlWeb.Plug.ValidateUser do
  @moduledoc ~S"""
  This plug handles ensuring that a user is in
  the assigns otherwise it forces a redirect.
  """
  import Plug.Conn
  alias NoodlWeb.Router.Helpers, as: Routes

  def init(options) do
    options
  end

  def handle_redirect(conn) do
    conn
    |> Phoenix.Controller.put_flash(:error, "You need to sign in or sign up before continuing.")
    |> Phoenix.Controller.redirect(to: Routes.accounts_path(conn, :login))
    |> halt()
  end

  def call(conn, _opts) do
    case conn do
      %{assigns: %{user: %{id: _id}}} ->
        conn

      _ ->
        handle_redirect(conn)
    end
  end
end
