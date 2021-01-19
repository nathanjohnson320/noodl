defmodule Noodl.Repo.Migrations.AddUserConfirmed do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :confirmed, :boolean, default: false
    end
  end
end
