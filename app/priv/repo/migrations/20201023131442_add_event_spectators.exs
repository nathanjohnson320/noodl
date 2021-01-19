defmodule Noodl.Repo.Migrations.AddEventSpectators do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add(:spectators, :boolean, default: false)
      add(:max_spectators, :integer)
    end
  end
end
