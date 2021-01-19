defmodule Noodl.Repo.Migrations.AddTicketAdmin do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :admin, :boolean, default: false
      modify :expires_at, :utc_datetime, from: :naive_datetime
      modify :redeemed_at, :utc_datetime, from: :naive_datetime
    end

    create index(:tickets, [:admin])
  end
end
