defmodule Noodl.Repo.Migrations.AddTicketPricePaid do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :price_paid, :integer
    end
  end
end
