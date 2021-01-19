defmodule Noodl.Repo.Migrations.SessionActivityUtcTime do
  use Ecto.Migration

  def change do
    alter table(:session_activities) do
      modify :inserted_at, :utc_datetime
      modify :updated_at, :utc_datetime
    end
  end
end
