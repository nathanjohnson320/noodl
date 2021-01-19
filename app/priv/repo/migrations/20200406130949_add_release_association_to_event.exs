defmodule Noodl.Repo.Migrations.AddReleaseAssociationToEvent do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :release_id, references(:releases, on_delete: :delete_all, type: :binary_id)
    end
  end
end
