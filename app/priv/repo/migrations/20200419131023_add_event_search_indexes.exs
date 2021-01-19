defmodule Noodl.Repo.Migrations.AddEventSearchIndexes do
  use Ecto.Migration

  def change do
    create index(:events, [:topic])
    create index(:events, [:language])
    create index(:events, [:timezone])
  end
end
