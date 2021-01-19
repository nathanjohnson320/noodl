defmodule NoodlWeb.ValidateSpectatorTest do
  use NoodlWeb.ConnCase

  import Noodl.Factory

  alias Noodl.{Events, Repo}
  alias NoodlWeb.Presence

  describe "call" do
    setup do
      on_exit(fn ->
        for pid <- Presence.fetchers_pids() do
          ref = Process.monitor(pid)
          assert_receive {:DOWN, ^ref, _, _, _}, 1000
        end
      end)
    end

    test "does not allow spectators if session.spectators is false", %{conn: conn} do
      session = insert(:session, spectators: false) |> Repo.preload(:event)

      conn =
        conn
        |> get(
          Routes.events_session_dashboard_path(
            conn,
            :dashboard,
            session.event.slug,
            session.slug
          )
        )

      assert html_response(conn, :found)
    end

    test "does allow spectators if session.spectators is true", %{conn: conn} do
      session = insert(:session, spectators: true) |> Repo.preload(:event)

      conn =
        conn
        |> get(
          Routes.events_session_dashboard_path(
            conn,
            :dashboard,
            session.event.slug,
            session.slug
          )
        )

      assert html_response(conn, :ok)
    end

    test "does not allow spectators if session.spectators is true but already at capacity", %{
      conn: conn
    } do
      user = Events.generate_anonymous_user()
      session = insert(:session, spectators: true, max_spectators: 1) |> Repo.preload(:event)

      Presence.track(
        self(),
        Events.session_channel_name(session),
        user.id,
        user
      )

      conn =
        conn
        |> get(
          Routes.events_session_dashboard_path(
            conn,
            :dashboard,
            session.event.slug,
            session.slug
          )
        )

      assert html_response(conn, :found)
    end

    test "does allow spectators if session.spectators is true and not at capacity", %{
      conn: conn
    } do
      user = Events.generate_anonymous_user()
      session = insert(:session, spectators: true, max_spectators: 2) |> Repo.preload(:event)

      Presence.track(
        self(),
        Events.session_channel_name(session),
        user.id,
        user
      )

      conn =
        conn
        |> get(
          Routes.events_session_dashboard_path(
            conn,
            :dashboard,
            session.event.slug,
            session.slug
          )
        )

      assert html_response(conn, :ok)
    end
  end
end
