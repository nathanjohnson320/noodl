defmodule Noodl.Repo.Migrations.AddEventIsLive do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :is_live, :boolean, default: false
    end

    create index(:events, [:is_live])
  end
end
