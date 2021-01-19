defmodule NoodlWeb.ReleaseController do
  use NoodlWeb, :controller

  alias Noodl.Ticketing
  alias Noodl.Ticketing.Cart
  alias NoodlWeb.Live
  alias NoodlWeb.Live.Ticketing.Release

  alias Phoenix.LiveView.Controller

  def completed(conn, _params) do
    conn
    |> delete_session(:releases)
    |> put_flash(
      :info,
      "Free Ticket(s) successfully processed! You may now proceed to the event."
    )
    |> redirect(to: Routes.live_path(conn, Live.Accounts.Events))
  end

  def checkout(%{assigns: %{user: user}} = conn, %{
        "stripe_token" => token,
        "payment" => %{"stripe_intent" => payment_intent}
      }) do
    with {:ok, cart} <- Cart.get(user),
         releases <- cart |> Ticketing.get_releases(),
         true <- Enum.all?(releases, &Ticketing.can_purchase_ticket?(user, &1)),
         {:ok, _} <-
           Stripe.PaymentIntent.confirm(payment_intent, %{
             payment_method_data: %{type: "card", card: %{token: token}}
           }),
         true <- Cart.empty(user) do
      conn
      |> put_flash(:info, "Ticket(s) successfully purchased!")
      |> redirect(to: Routes.live_path(conn, Live.Pages.Index))
    else
      e ->
        IO.inspect(e)

        conn
        |> put_flash(:info, "Error purchasing tickets.")
        |> Controller.live_render(Release.Checkout)
    end
  end

  def checkout(%{assigns: %{user: user}} = conn, %{
        "removed" => removed
      }) do
    releases =
      conn
      |> get_session(:releases)

    updated_releases = Map.delete(releases, removed)

    conn
    |> put_session(:releases, updated_releases)
    |> Controller.live_render(Release.Checkout,
      session: %{"user" => user, "releases" => updated_releases}
    )
  end

  def checkout(%{assigns: %{user: user}} = conn, _params) do
    # Case when people are navigating straight to checkout and not from exp page
    releases = conn |> get_session(:releases) || %{}

    conn
    |> put_session(:releases, releases)
    |> Controller.live_render(Release.Checkout,
      session: %{"user" => user, "releases" => releases}
    )
  end
end
