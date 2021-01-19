defmodule NoodlWeb.LiveEventsShow do
  use NoodlWeb.ConnCase

  import Noodl.Factory

  describe "Logged In" do
    test "renders an event" do
      conn = session_conn()

      user = insert(:user)
      conn = conn |> put_session(:user, user.id)
      event = insert(:event, creator: user)

      conn =
        conn
        |> get(
          Routes.events_show_path(
            conn,
            :show,
            event.slug
          )
        )

      assert html_response(conn, :ok)
    end
  end

  describe "Not Logged In" do
    test "renders an event" do
      conn = session_conn()

      event = insert(:event, creator: insert(:user))

      conn =
        conn
        |> get(
          Routes.events_show_path(
            conn,
            :show,
            event.slug
          )
        )

      assert html_response(conn, :ok)
    end
  end
end
