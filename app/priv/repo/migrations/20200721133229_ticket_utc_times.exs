defmodule Noodl.Repo.Migrations.TicketUtcTimes do
  use Ecto.Migration

  def change do
    alter table(:releases) do
      modify :start_at, :utc_datetime
      modify :end_at, :utc_datetime
    end
  end
end
