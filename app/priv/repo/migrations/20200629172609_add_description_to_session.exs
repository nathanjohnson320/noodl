defmodule Noodl.Repo.Migrations.AddDescriptionToSession do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :description, :text
    end
  end
end
