defmodule Noodl.Repo.Migrations.AddEnded do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :status, :string, default: "initialized"
    end
  end
end
