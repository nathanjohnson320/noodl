defmodule NoodlWeb.WebhookController do
  use NoodlWeb, :controller

  alias Noodl.Accounts
  alias Noodl.Ticketing
  alias Noodl.Ticketing.Ticket
  alias NoodlWeb.Endpoint

  def stripe(
        conn,
        %{
          "data" => %{
            "object" => %{
              "metadata" => %{"user" => user, "type" => "ticket"} = params,
              "id" => charge_id
            }
          },
          "type" => "payment_intent.succeeded"
        }
      ) do
    # Lookup the user by their email
    user = Accounts.get_user!(user)

    # Get all the releases, everything that isn't user
    _tickets =
      params
      |> Map.delete("user")
      |> Map.delete("type")
      |> Ticketing.cleanup_release_quantities()
      |> Ticketing.get_releases()
      |> Enum.flat_map(fn release ->
        # Create a ticket for each release of the given quantity
        for _i <- Range.new(1, release.purchase_quantity) do
          Ticketing.create_ticket(
            %Ticket{
              user_id: user.id,
              release_id: release.id,
              event_id: release.event_id
            },
            %{
              "code" => UUID.uuid4(),
              "expires_at" => release.event.end_datetime,
              "name" => release.title,
              "paid" => true,
              "charge_id" => charge_id,
              "price_paid" => release.price
            }
          )
        end
      end)

    # Broadcast that the tickets were purchased
    Endpoint.broadcast!(
      "user:#{user.id}",
      "ticket_purchase",
      %{"transaction_id" => charge_id}
    )

    conn
    |> resp(200, "")
  end

  def stripe(conn, _params) do
    conn
    |> resp(200, "")
  end
end
