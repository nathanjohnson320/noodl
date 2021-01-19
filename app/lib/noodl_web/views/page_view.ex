defmodule NoodlWeb.PageView do
  use NoodlWeb, :view

  def format_time(time, str) do
    case Timex.format(time, str, :strftime) do
      {:ok, time} -> time
      _ -> ""
    end
  end

  def truncate_description(desc), do: String.slice(desc, 0..120) <> "..."

  def event_price(%{releases: releases}) when length(releases) > 0 do
    release = List.first(releases)
    "#{release.price}/ticket"
  end

  def event_price(_event), do: ""

  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
end
