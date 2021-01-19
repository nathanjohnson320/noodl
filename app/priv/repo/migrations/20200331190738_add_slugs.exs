defmodule Noodl.Repo.Migrations.AddSlugs do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :slug, :string
    end

    create unique_index(:events, [:name])
    create unique_index(:events, [:slug])
  end
end
