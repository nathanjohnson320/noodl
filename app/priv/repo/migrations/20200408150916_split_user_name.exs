defmodule Noodl.Repo.Migrations.SplitUserName do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :name
      add :firstname, :string
      add :lastname, :string
    end
  end

  def down do
    alter table(:users) do
      remove :firstname
      remove :lastname, :string
      add :name, :string
    end
  end
end
