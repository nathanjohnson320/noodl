defmodule NoodlWeb.Plug.Authentication do
  @moduledoc ~S"""
  This plug handles populating assigns in the conn based on
  ids stored in the session.
  """
  import Plug.Conn

  import Phoenix.LiveView, only: [assign_new: 3]

  alias Noodl.Accounts

  def retrieve_user(conn) do
    case conn.assigns do
      %{user: user} -> {:ok, user}
      _ -> {:error, :no_user}
    end
  end

  def init(_params) do
  end

  def call(conn, _params) do
    # Check if there's a user
    conn = fetch_cookies(conn, signed: ~w(ack))

    case get_session(conn, :user) || get_in(conn.cookies, ["ack", :user_id]) do
      nil ->
        # No user then return conn
        conn

      user_id ->
        # Lookup the user if they still exist then populate them
        # Must be confirmed
        case Accounts.get_user(user_id) do
          {:ok, %{confirmed: true} = user} ->
            conn
            |> put_session(:user, user.id)
            |> assign(:user, user)

          _ ->
            conn
            |> delete_session(:user)
        end
    end
  end

  def assign_user(socket, params) do
    # Check if there's a user
    case params["user"] do
      nil ->
        # No user then return socket
        socket
        |> assign_new(:user, fn -> nil end)

      user_id ->
        # Lookup the user if they still exist then populate them
        # Must be confirmed
        case Accounts.get_user(user_id) do
          {:ok, %{confirmed: true} = user} ->
            tz = Phoenix.LiveView.get_connect_params(socket)["timezone"] || "America/New_York"

            socket
            |> assign_new(:user, fn -> user end)
            |> assign_new(:user_timezone, fn ->
              tz
            end)

          _ ->
            socket
        end
    end
  end
end
