defmodule Noodl.Repo.Migrations.DropEventTiers do
  use Ecto.Migration

  def change do
    alter table(:events) do
      remove :event_tier_id
    end

    drop table(:event_tiers)
  end
end
