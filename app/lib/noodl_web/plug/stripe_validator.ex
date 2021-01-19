defmodule NoodlWeb.Plug.StripeValidator do
  @moduledoc ~S"""
  Plug to handle verifying inbound webhook requests from stripe
  """
  import Plug.Conn

  alias NoodlWeb.Plug.BodyReader

  def init(options) do
    options
  end

  def call(conn, _opts) do
    signature_header = List.first(get_req_header(conn, "stripe-signature"))
    raw_body = BodyReader.read_cached_body(conn)
    secret = System.get_env("STRIPE_WEBHOOK_SECRET")

    case Stripe.Webhook.construct_event(raw_body, signature_header, secret) do
      {:ok, %Stripe.Event{}} ->
        conn

      _ ->
        conn
        |> resp(200, "")
        |> halt()
    end
  end
end
