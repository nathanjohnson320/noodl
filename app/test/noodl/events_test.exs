defmodule Noodl.EventsTest do
  use Noodl.DataCase

  alias Noodl.Events
  alias Noodl.Repo

  describe "list_events_by_search/4" do
    test "should return events ending one hour from now" do
      now = Timex.now()
      start_time = Timex.shift(now, minutes: 1)
      end_time = Timex.shift(start_time, minutes: 1)

      event =
        insert(:event,
          is_live: true,
          start_datetime: start_time,
          end_datetime: end_time,
          timezone: "America/New_York"
        )
        |> Repo.preload(:releases)

      assert Events.list_events_by_search(event.name, 10, 0) == [event]
    end
  end
end
