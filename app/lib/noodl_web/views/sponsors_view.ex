defmodule NoodlWeb.SponsorsView do
  use NoodlWeb, :view

  use Timex

  def sponsor_photo_url(sponsor) do
    Noodl.Uploaders.SponsorPhoto.url({sponsor.image, sponsor})
  end

  defdelegate strip_whitespace(str), to: NoodlWeb.ReleaseView
end
