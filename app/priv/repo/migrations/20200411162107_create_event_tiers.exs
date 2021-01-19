defmodule Noodl.Repo.Migrations.CreateEventTiers do
  use Ecto.Migration

  def change do
    create table(:event_tiers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :locale, :string, default: "en-US"
      add :descriptions, {:array, :string}
      add :max_viewers, :integer
      add :order, :integer
      add :summary, :string
      add :has_unlimited_viewers, :boolean, default: false, null: false
      add :price, :integer
      add :title, :string

      timestamps()
    end

    alter table(:events) do
      add :event_tier_id,
          references(:event_tiers, on_delete: :delete_all, type: :binary_id)

      add :is_paid, :boolean, default: false
    end

    create index(:events, [:is_paid])
  end
end
