defmodule Noodl.Repo.Migrations.AddSlugUniques do
  use Ecto.Migration

  def change do
    create unique_index(:sessions, [:event_id, :slug])
  end
end
