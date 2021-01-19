defmodule NoodlWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest

      alias NoodlWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint NoodlWeb.Endpoint

      alias Plug.Session

      def session_conn() do
        opts =
          Session.init(
            store: :cookie,
            key: "foobar",
            encryption_salt: "encrypted cookie salt",
            signing_salt: "signing salt",
            log: false,
            encrypt: false
          )

        build_conn()
        |> Session.call(opts)
        |> fetch_session()
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Noodl.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Noodl.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
