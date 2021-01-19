defmodule NoodlWeb.SessionView do
  use NoodlWeb, :view

  alias Noodl.Events

  def format_session_start_time(%{start_datetime: start_datetime}, event) do
    start_datetime = Timex.to_datetime(start_datetime, event.timezone)

    case Timex.format(start_datetime, "%I %p %Z", :strftime) do
      {:ok, time} -> "#{Timex.from_now(start_datetime)} at #{time}"
      _ -> ""
    end
  end

  def within_allowed_time?(session, now) do
    %{timezone: timezone} = session.event

    start_time =
      Events.appropriate_timezone(session.start_datetime, timezone)
      |> Timex.shift(minutes: -30)

    end_time =
      Events.appropriate_timezone(session.end_datetime, timezone)
      |> Timex.shift(minutes: 10)

    Timex.before?(start_time, now) and Timex.before?(now, end_time)
  end

  def bounds_error(%Ecto.Changeset{} = changeset) do
    case changeset.errors[:start_datetime_bounds] do
      {error, _} -> error
      _ -> ""
    end
  end

  defdelegate cover_photo_url(event), to: NoodlWeb.EventsView
  defdelegate pretty_manage_date(event, date), to: NoodlWeb.EventsView
  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
  defdelegate get_username(user), to: NoodlWeb.SharedView
end
