defmodule NoodlWeb.LayoutView do
  use NoodlWeb, :view

  alias NoodlWeb.Endpoint
  alias NoodlWeb.Router

  def full_url(uri) do
    cur_url = Endpoint.struct_url()
    Router.Helpers.url(cur_url) <> uri
  end

  def secure_url(url) do
    uri = URI.parse(url)

    %URI{uri | scheme: "https", port: 443} |> to_string()
  end
end
