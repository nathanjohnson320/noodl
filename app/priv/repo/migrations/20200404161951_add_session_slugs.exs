defmodule Noodl.Repo.Migrations.AddSessionSlugs do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :slug, :string
    end

    create unique_index(:sessions, [:event_id, :name])
  end
end
