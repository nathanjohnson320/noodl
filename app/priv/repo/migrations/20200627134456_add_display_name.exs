defmodule Noodl.Repo.Migrations.AddDisplayName do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :display_name, :string, size: 64
    end
  end
end
