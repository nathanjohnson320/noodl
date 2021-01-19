defmodule Noodl.Repo.Migrations.CreateEventsOrganizers do
  use Ecto.Migration

  def change do
    create table(:events_organizers) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)
    end

    create unique_index(:events_organizers, [:user_id, :event_id])
  end
end
