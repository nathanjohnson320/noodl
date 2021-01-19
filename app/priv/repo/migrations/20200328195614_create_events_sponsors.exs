defmodule Noodl.Repo.Migrations.CreateEventsSponsors do
  use Ecto.Migration

  def change do
    create table(:events_sponsors) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)
    end

    create unique_index(:events_sponsors, [:user_id, :event_id])
  end
end
