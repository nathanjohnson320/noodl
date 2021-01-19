defmodule Noodl.Repo.Migrations.AddRecordingType do
  use Ecto.Migration

  def change do
    alter table(:recordings) do
      add :type, :string, default: "system"
    end
  end
end
