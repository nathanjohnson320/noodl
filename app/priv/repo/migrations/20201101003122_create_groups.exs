defmodule Noodl.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :users, {:array, :binary_id}

      timestamps()
    end
  end
end
