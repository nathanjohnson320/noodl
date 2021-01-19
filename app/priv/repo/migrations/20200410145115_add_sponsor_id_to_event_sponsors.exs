defmodule Noodl.Repo.Migrations.AddSponsorIdToEventsSponsors do
  use Ecto.Migration

  def up do
    drop unique_index(:events_sponsors, [:user_id, :event_id])

    alter table(:events_sponsors) do
      add :sponsor_id, references(:sponsors, on_delete: :delete_all, type: :binary_id)
      remove :user_id
    end

    create unique_index(:events_sponsors, [:sponsor_id, :event_id])
  end

  def down do
    alter table(:events_sponsors) do
      remove :sponsor_id, references(:sponsors, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
    end

    create unique_index(:events_sponsors, [:user_id, :event_id])
  end
end
