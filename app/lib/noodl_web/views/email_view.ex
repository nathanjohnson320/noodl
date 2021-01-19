defmodule NoodlWeb.EmailView do
  use NoodlWeb, :view

  alias NoodlWeb.Endpoint
  alias NoodlWeb.Router

  def full_url(uri) do
    cur_url = Endpoint.struct_url()
    Router.Helpers.url(cur_url) <> uri
  end

  def unsubscribe_link(user, type) do
    token = Phoenix.Token.sign(Endpoint, "noodl unsubscribe", %{email: user.email, type: type})
    full_url("/unsubscribe?token=#{token}")
  end
end
