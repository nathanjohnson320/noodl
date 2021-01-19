defmodule NoodlWeb.Live.Ticketing.Release.Checkout do
  @moduledoc ~S"""
  LiveView for the release purchase.
  """
  use NoodlWeb, :live_view

  alias NoodlWeb.ReleaseView
  alias Noodl.Ticketing
  alias Noodl.Ticketing.Cart

  @minimum_price Money.new(250)

  def mount(
        _params,
        session,
        socket
      ) do
    %{assigns: %{user: user}} = socket = Authentication.assign_user(socket, session)

    case Cart.get(user) do
      {:ok, cart} when cart != %{} ->
        releases = Ticketing.get_releases(cart)
        total = Ticketing.get_ticket_total(releases)

        total =
          if Money.compare(total, @minimum_price) < 0 do
            @minimum_price
          else
            total
          end

        release_errors =
          Enum.reduce(releases, %{}, fn release, acc ->
            if Ticketing.can_purchase_ticket?(user, release),
              do: acc,
              else: Map.put(acc, release.id, true)
          end)

        {:ok,
         assign(socket,
           releases: releases,
           release_errors: release_errors,
           submitting: false,
           total: total,
           payment_intent: create_payment_intent(user, total, releases)
         )}

      _ ->
        {:ok,
         socket
         |> put_flash(:info, "Your cart is empty!")
         |> push_redirect(to: Routes.live_path(socket, Live.Pages.Index))}
    end
  end

  def create_payment_intent(user, %{amount: amount}, releases) do
    releases =
      for release <- releases, into: %{} do
        # Purchase quantity is a fake field to hold how many tickets they bought
        {release.id, release.purchase_quantity}
      end

    {:ok, payment_intent} =
      Stripe.PaymentIntent.create(%{
        amount: amount,
        currency: "usd",
        metadata: Map.merge(releases, %{user: user.id, type: "ticket"}),
        receipt_email: user.email
      })

    payment_intent
  end

  def handle_event("processing", _, socket) do
    {:noreply, assign(socket, submitting: true, error_message: "")}
  end

  def handle_event("processing_failed", _, socket) do
    {:noreply, assign(socket, submitting: false, error_message: "")}
  end

  def handle_event("delete_item", %{"id" => id}, %{assigns: %{user: user}} = socket) do
    case Cart.remove_tickets(user, id) do
      {:ok, _cart} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cart Updated Successfully!")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Cart could not be updated at this time.")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}
    end
  end

  def subtotal(release) do
    Money.multiply(release.price, release.purchase_quantity)
  end

  defdelegate get_purchase_submit_classes(t), to: ReleaseView
  defdelegate submit_disabled?(t), to: ReleaseView
  defdelegate cover_photo_url(event), to: NoodlWeb.EventsView
  defdelegate pretty_manage_date(event, date), to: NoodlWeb.EventsView
end
