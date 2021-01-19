defmodule NoodlWeb.EventSessionTest do
  use Noodl.DataCase, async: false
  import Phoenix.ChannelTest

  import Mox

  alias Noodl.Events
  alias Noodl.Repo
  alias Noodl.Events.Event.Session
  alias NoodlWeb.Endpoint

  setup :set_mox_global

  @tz "America/New_York"

  describe "initialize/1" do
    test "does not start pid if outside the allowed time" do
      now = Timex.now()
      start_time = Timex.shift(now, minutes: 31)
      end_time = Timex.shift(start_time, minutes: 30)

      session =
        insert(:session, start_datetime: start_time, end_datetime: end_time)
        |> Repo.preload(:event)

      assert is_nil(Session.initialize(session))
    end

    test "starts a new session if inside the allowed time" do
      now = Timex.now(@tz)
      end_time = Timex.shift(now, minutes: 30) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session,
          start_datetime: now |> Events.appropriate_timezone("Etc/UTC", @tz),
          end_datetime: end_time
        )
        |> Repo.preload(:event)

      assert is_pid(Session.initialize(session))
    end

    test "returns the same pid if it's already registered" do
      now = Timex.now(@tz)
      start_time = now |> Events.appropriate_timezone("Etc/UTC", @tz)
      end_time = Timex.shift(now, minutes: 30) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session,
          start_datetime: start_time,
          end_datetime: end_time
        )
        |> Repo.preload(:event)

      pid = Session.initialize(session)
      assert is_pid(pid)
      assert Session.initialize(session) == pid
    end
  end

  describe "mounted/2" do
    test "Returns default times if the pid is nil" do
      now = Timex.now("America/New_York")
      start_time = Timex.shift(now, minutes: 31)
      end_time = Timex.shift(start_time, minutes: 30)

      session =
        insert(:session,
          start_datetime: start_time,
          end_datetime: end_time
        )
        |> Repo.preload(:event)

      pid = Session.initialize(session)

      assert %{
               time_elapsed: %Time{hour: 0, minute: 0},
               time_left: %NaiveDateTime{hour: 1, minute: 0}
             } = Session.mounted(pid, session)
    end

    test "returns time elapsed and time left if session has started" do
      now = Timex.now()
      end_time = Timex.shift(now, minutes: 30)

      session =
        insert(:session, start_datetime: now, end_datetime: end_time)
        |> Repo.preload(:event)

      pid = Session.initialize(session)

      assert %{
               time_elapsed: %Time{hour: 0, minute: 0},
               time_left: %NaiveDateTime{minute: 29}
             } = Session.mounted(pid, session)
    end
  end

  describe "ready/1" do
    test "sets the session.status to ready" do
      now = Timex.now(@tz)
      end_time = now |> Timex.shift(minutes: 30) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session,
          start_datetime: now |> Events.appropriate_timezone("Etc/UTC", @tz),
          end_datetime: end_time
        )
        |> Repo.preload(:event)

      Endpoint.subscribe("session:#{session.id}")

      pid = Session.initialize(session)
      assert is_pid(pid)

      assert :ok == Session.ready(pid)

      assert_broadcast(
        "status",
        %{
          status: "ready",
          session: %{
            status: "ready"
          }
        },
        5_000
      )

      session = Repo.get!(Noodl.Events.Session, session.id)
      assert session.status == "ready"
    end
  end

  describe "connected/1" do
    test "sets the session.status to connected" do
      now = Timex.now(@tz)
      end_time = Timex.shift(now, minutes: 30) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session,
          start_datetime: now |> Events.appropriate_timezone("Etc/UTC", @tz),
          end_datetime: end_time
        )
        |> Repo.preload(:event)

      RecordingApiClientBehaviourMock
      |> expect(:acquire, fn _ ->
        {:ok, %{"resourceId" => "an id"}}
      end)

      RecordingApiClientBehaviourMock
      |> expect(:start_pip, fn _, _, _ ->
        {:ok, %{"resourceId" => "an id", "sid" => "an sid"}}
      end)

      Endpoint.subscribe("session:#{session.id}")

      pid = Session.initialize(session)
      assert is_pid(pid)

      assert :ok == Session.connected(pid)

      assert_broadcast(
        "status",
        %{
          status: "connected",
          session: %{
            status: "connected"
          }
        },
        5_000
      )

      session = Repo.get!(Noodl.Events.Session, session.id)
      assert session.status == "connected"
    end
  end

  describe "starting/1" do
    test "sets the session.status to starting" do
      now = Timex.now(@tz)
      end_time = Timex.shift(now, minutes: 30) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session,
          start_datetime: now |> Events.appropriate_timezone("Etc/UTC", @tz),
          end_datetime: end_time
        )
        |> Repo.preload(:event)

      Endpoint.subscribe("session:#{session.id}")

      pid = Session.initialize(session)
      assert is_pid(pid)

      assert :ok == Session.starting(pid)

      assert_broadcast(
        "status",
        %{
          status: "starting",
          session: %{
            status: "starting"
          }
        },
        5_000
      )

      session = Repo.get!(Noodl.Events.Session, session.id)
      assert session.status == "starting"
    end
  end

  describe "disconnected/1" do
    test "sets the session.status to disconnected" do
      now = Timex.now(@tz)
      end_time = Timex.shift(now, minutes: 30) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session,
          start_datetime: now |> Events.appropriate_timezone("Etc/UTC", @tz),
          end_datetime: end_time
        )
        |> Repo.preload(:event)

      Endpoint.subscribe("session:#{session.id}")

      pid = Session.initialize(session)
      assert is_pid(pid)

      assert :ok == Session.disconnected(pid)

      assert_broadcast(
        "status",
        %{
          status: "disconnected",
          session: %{
            status: "disconnected"
          }
        },
        5_000
      )

      session = Repo.get!(Noodl.Events.Session, session.id)
      assert session.status == "disconnected"
    end
  end

  describe "ended/1" do
    test "sets the session.status to ended and kills the process" do
      now = Timex.now(@tz)
      end_time = Timex.shift(now, minutes: 30) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session,
          start_datetime: now |> Events.appropriate_timezone("Etc/UTC", @tz),
          end_datetime: end_time
        )
        |> Repo.preload(:event)

      insert(:recording, session: session)

      Endpoint.subscribe("session:#{session.id}")

      pid = Session.initialize(session)
      assert is_pid(pid)

      RecordingApiClientBehaviourMock
      |> expect(:stop, fn _, _, _ ->
        {:ok, %{"id" => "an id"}}
      end)

      assert :ok == Session.ended(pid)

      assert_broadcast(
        "status",
        %{
          status: "ended",
          session: %{
            status: "ended"
          }
        },
        8_000
      )

      session = Repo.get!(Noodl.Events.Session, session.id)
      assert session.status == "ended"
      refute Process.alive?(pid)
    end

    test "automatically kills the pid if it's past 10 minutes" do
      now = Timex.now(@tz)
      start_time = Timex.shift(now, minutes: -40) |> Events.appropriate_timezone("Etc/UTC", @tz)

      end_time =
        Timex.shift(now, minutes: -9, seconds: -58) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session, start_datetime: start_time, end_datetime: end_time)
        |> Repo.preload(:event)

      insert(:recording, session: session)

      RecordingApiClientBehaviourMock
      |> expect(:stop, fn _, _, _ ->
        {:ok, %{"id" => "an id"}}
      end)

      Endpoint.subscribe("session:#{session.id}")

      pid = Session.initialize(session)
      assert is_pid(pid)

      assert_broadcast(
        "status",
        %{
          status: "ended",
          session: %{
            status: "ended"
          }
        },
        5_000
      )

      session = Repo.get!(Noodl.Events.Session, session.id)
      assert session.status == "ended"
      refute Process.alive?(pid)
    end
  end

  describe "add_presenters/2" do
    test "should be able to add and remove a presenter and broadcast it out" do
      %{id: id} = insert(:user)

      now = Timex.now(@tz)
      end_time = Timex.shift(now, minutes: 30) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session,
          start_datetime: now |> Events.appropriate_timezone("Etc/UTC", @tz),
          end_datetime: end_time
        )
        |> Repo.preload(:event)

      insert(:recording, session: session)

      Endpoint.subscribe("session:#{session.id}")

      pid = Session.initialize(session)
      assert is_pid(pid)
      session_state = Session.mounted(pid, session)

      RecordingApiClientBehaviourMock
      |> expect(:stop, fn _, _, _ ->
        {:ok, %{"id" => "an id"}}
      end)

      assert session_state.presenters == MapSet.new()

      assert :ok == Session.add_presenter(pid, %{"id" => id, "role" => :host})

      new_presenters = MapSet.new([id])

      assert_broadcast(
        "added_presenter",
        %{
          presenter: ^id,
          presenters: ^new_presenters
        },
        5_000
      )

      session_state = Session.mounted(pid, session)
      assert session_state.presenters == new_presenters

      new_presenters = MapSet.new()
      assert :ok == Session.remove_presenter(pid, %{"id" => id, "role" => :host})

      assert_broadcast(
        "removed_presenter",
        %{
          presenter: ^id,
          presenters: ^new_presenters
        },
        5_000
      )

      session_state = Session.mounted(pid, session)
      assert session_state.presenters == new_presenters
    end

    test "should not be able to add presenter if there are already 17 (max)" do
      now = Timex.now(@tz)
      start_time = now |> Events.appropriate_timezone("Etc/UTC", @tz)
      end_time = Timex.shift(now, minutes: 30) |> Events.appropriate_timezone("Etc/UTC", @tz)

      session =
        insert(:session, start_datetime: start_time, end_datetime: end_time)
        |> Repo.preload(:event)

      insert(:recording, session: session)

      Endpoint.subscribe("session:#{session.id}")

      pid = Session.initialize(session)
      assert is_pid(pid)

      RecordingApiClientBehaviourMock
      |> expect(:stop, fn _, _, _ ->
        {:ok, %{"id" => "an id"}}
      end)

      ids =
        Enum.map(1..17, fn _i ->
          %{id: id} = insert(:user)
          assert :ok == Session.add_presenter(pid, %{"id" => id, "role" => :host})

          assert_broadcast(
            "added_presenter",
            %{
              presenter: ^id
            },
            5_000
          )

          id
        end)

      session_state = Session.mounted(pid, session)
      new_presenters = MapSet.new(ids)
      assert session_state.presenters == new_presenters

      %{id: id} = insert(:user)
      assert :ok == Session.add_presenter(pid, %{"id" => id, "role" => :host})

      assert_broadcast(
        "session_error",
        %{
          message: "Maximum number of presenters reached"
        },
        5_000
      )

      session_state = Session.mounted(pid, session)
      assert session_state.presenters == new_presenters
    end
  end
end
