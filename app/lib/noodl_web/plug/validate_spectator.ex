defmodule NoodlWeb.Plug.ValidateSpectator do
  @moduledoc ~S"""
  Plug to handle max_spectator count and the spectator flag on a session
  """
  import Plug.Conn

  alias Noodl.Events
  alias Phoenix.Controller
  alias NoodlWeb.Router.Helpers, as: Routes

  def init(options) do
    options
  end

  def call(conn, _opts \\ []) do
    case conn do
      %{assigns: %{user: %{id: _id}}} ->
        conn

      _ ->
        event = Events.get_event_by!(slug: conn.params["event"])

        session =
          Events.get_session_by!(slug: conn.params["session"], event_id: event.id)

        if not session.spectators or Events.session_at_capacity?(session) do
          conn
          |> Controller.put_flash(
            :error,
            "This session is at capacity for spectators. Get a ticket to join!"
          )
          |> Controller.redirect(to: Routes.events_show_path(conn, :show, event.slug))
          |> halt()
        else
          conn
        end
    end
  end
end
