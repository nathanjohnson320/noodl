defmodule NoodlWeb.SessionViewTest do
  use NoodlWeb.ConnCase, async: true

  import Noodl.Factory

  alias Noodl.Events
  alias Noodl.Repo
  alias NoodlWeb.SessionView

  describe "too_early?/2" do
    test "false if it's not 30 minutes before current time" do
      now = Timex.now()
      session = insert(:session, start_datetime: now) |> Repo.preload(:event)

      refute SessionView.too_early?(session, now)
    end

    test "false if it's after the session ends" do
      now = Timex.now()
      thirty_minutes_from_now = Timex.shift(now, minutes: 30)
      more_than_thirty_minutes = Timex.shift(thirty_minutes_from_now, minutes: 30)

      session =
        insert(:session, start_datetime: now, end_datetime: thirty_minutes_from_now)
        |> Repo.preload(:event)

      refute SessionView.too_early?(session, more_than_thirty_minutes)
    end

    test "true if before 30 minutes ago" do
      now = Timex.now()
      thirty_minutes_from_now = Timex.shift(now, minutes: 30, seconds: 1)

      session = insert(:session, start_datetime: thirty_minutes_from_now) |> Repo.preload(:event)

      assert SessionView.too_early?(session, now)
    end
  end

  describe "within_allowed_time?/2" do
    test "true if it's 30 minutes before current time" do
      tz = "America/New_York"
      now = Timex.now(tz)
      start_time = Timex.shift(now, minutes: 30) |> Events.appropriate_timezone("Etc/UTC", tz)
      end_time = Timex.shift(now, minutes: 60) |> Events.appropriate_timezone("Etc/UTC", tz)

      session =
        insert(:session, start_datetime: start_time, end_datetime: end_time)
        |> Repo.preload(:event)

      assert SessionView.within_allowed_time?(session, now)
    end

    test "true if it's between start and end" do
      now = Timex.now()
      start_time = Timex.shift(now, minutes: -15)
      end_time = Timex.shift(start_time, minutes: 30)

      session =
        insert(:session, start_datetime: start_time, end_datetime: end_time)
        |> Repo.preload(:event)

      assert SessionView.within_allowed_time?(session, now)
    end

    test "true if it's after session end but before 10 minutes over" do
      now = Timex.now()
      # Should give us a 9 minute after ending time (39:59 minutes ago plus 30 is 9:59)
      start_time = Timex.shift(now, minutes: -39, seconds: 59)
      end_time = Timex.shift(start_time, minutes: 30)

      session =
        insert(:session, start_datetime: start_time, end_datetime: end_time)
        |> Repo.preload(:event)

      assert SessionView.within_allowed_time?(session, now)
    end

    test "false if it's over 10 minutes over" do
      now = Timex.now()
      start_time = Timex.shift(now, minutes: -40)
      end_time = Timex.shift(start_time, minutes: 30)

      session =
        insert(:session, start_datetime: start_time, end_datetime: end_time)
        |> Repo.preload(:event)

      refute SessionView.within_allowed_time?(session, now)
    end

    test "false if it's before 30 minutes before" do
      now = Timex.now()
      start_time = Timex.shift(now, minutes: 31)
      end_time = Timex.shift(start_time, minutes: 30)

      session =
        insert(:session, start_datetime: start_time, end_datetime: end_time)
        |> Repo.preload(:event)

      refute SessionView.within_allowed_time?(session, now)
    end
  end
end
