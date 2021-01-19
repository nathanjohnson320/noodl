defmodule Noodl.Repo.Migrations.AddRedeemedAtToTicket do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :redeemed_at, :naive_datetime
    end
  end
end
