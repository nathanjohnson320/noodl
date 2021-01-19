defmodule NoodlWeb.EventsView do
  use NoodlWeb, :view

  alias Noodl.Events

  def languages do
    langues = [
      "Arabic",
      "English",
      "Esperanto",
      "Filipino",
      "French",
      "German",
      "Hindi",
      "Japanese",
      "Korean",
      "Mandarin Chinese",
      "Portuguese",
      "Russian",
      "Spanish",
      "Thai",
      "Turkish",
      "Ukrainian",
      "Vietnamese",
      "Wu Chinese"
    ]

    default = [[key: "Select an option", value: "", disabled: true]]

    Enum.concat(default, langues)
  end

  def combine_topics(nil), do: ""

  def combine_topics(topics) do
    Enum.join(topics, ", ")
  end

  def pretty_event_date(event, tz \\ nil) do
    start_datetime = Timex.to_datetime(event.start_datetime, tz || event.timezone)
    end_datetime = Timex.to_datetime(event.start_datetime, tz || event.timezone)

    start_date = Timex.format!(start_datetime, "%B %e", :strftime)
    end_date = Timex.format!(end_datetime, "%B %e, %Y", :strftime)

    if DateTime.to_date(start_datetime) == DateTime.to_date(end_datetime) do
      "#{end_date}"
    else
      "#{start_date} - #{end_date}"
    end
  end

  def cover_photo_url(event) do
    Noodl.Uploaders.CoverPhoto.url({event.cover_photo, event}, :thumb)
  end

  def social_url(speaker) do
    "https://twitter.com/#{speaker.social_url}"
  end

  def speakers(sessions) do
    sessions
    |> Enum.reduce([], fn {_date, sessions}, acc ->
      sessions |> Enum.map(& &1.presenters) |> List.flatten(acc)
    end)
  end

  def date(datetime) do
    Timex.format!(datetime, "%B %e", :strftime)
  end

  def day(datetime) do
    Timex.format!(datetime, "%A", :strftime)
  end

  def time(time, tz, desired_tz) do
    datetime = Events.appropriate_timezone(time, tz, desired_tz)

    Timex.format!(datetime, "%l:%M %p", :strftime)
  end

  def get_purchase_submit_classes(assigns) do
    case assigns do
      %{submitting: true} ->
        "bg-red-500 text-white pr-6 pl-6 pt-2 pb-2 rounded-full mt-4 opacity-50 pointer-events-none"

      _ ->
        "bg-red-500 text-white pr-6 pl-6 pt-2 pb-2 rounded-full mt-4"
    end
  end

  def event_starts_in(event) do
    Timex.from_now(event.start_datetime)
  end

  def pretty_manage_date(event, date) do
    datetime = Events.appropriate_timezone(date, event.timezone, event.timezone)

    Timex.format!(
      datetime,
      "%B %d, %Y at %l:%M %p",
      :strftime
    )
  end

  def event_setup?(steps) do
    Enum.all?(steps, fn {_, condition, _} ->
      condition
    end)
  end

  def timezones() do
    default = [[key: "Select an option", value: "", disabled: true]]

    Enum.concat(default, Tzdata.zone_list())
  end

  def topics do
    [
      "Software Development",
      "Business",
      "Finance & Accounting",
      "Office Productivity",
      "Personal Development",
      "Design",
      "Marketing",
      "Lifestyle",
      "Health & Fitness",
      "Music",
      "Teaching & Academics",
      "Gaming"
    ]
  end

  def user_timezone(%{assigns: %Phoenix.LiveView.Socket.AssignsNotInSocket{}}),
    do: "America/New_York"

  def user_timezone(%{assigns: assigns}) when is_map(assigns) do
    assigns[:user_timezone] || "America/New_York"
  end

  def user_timezone(_), do: "America/New_York"

  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
  defdelegate sponsor_photo_url(user), to: NoodlWeb.SponsorsView
  defdelegate gravatar_url(user), to: NoodlWeb.AccountsView
  defdelegate get_username(user), to: NoodlWeb.SharedView
end
