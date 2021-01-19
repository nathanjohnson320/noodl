defmodule Noodl.Repo.Migrations.AddEventToSponsor do
  use Ecto.Migration

  def change do
    alter table(:sponsors) do
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)
    end

    create unique_index(:sponsors, [:event_id, :name])
  end
end
