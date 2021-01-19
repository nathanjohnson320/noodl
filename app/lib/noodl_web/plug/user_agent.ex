defmodule NoodlWeb.Plug.UserAgent do
  @moduledoc ~S"""
  This plug handles populating assigns in the conn based on
  ids stored in the session.
  """
  import Plug.Conn

  def init(_params) do
  end

  def call(conn, _params) do
    case conn
         |> Plug.Conn.get_req_header("user-agent")
         |> List.first()
         |> UAParser.parse() do
      %{
        family: "Chrome",
        os: %{
          family: "Windows"
        },
        version: %UAParser.Version{
          major: version
        }
      }
      when version >= 73 ->
        conn
        |> put_session(:capability, :enhanced)

      _ ->
        conn
        |> put_session(:capability, :general)
    end
  end
end
