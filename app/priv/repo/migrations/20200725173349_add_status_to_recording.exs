defmodule Noodl.Repo.Migrations.AddStatusToRecording do
  use Ecto.Migration

  def change do
    alter table(:recordings) do
      add :status, :string
    end

    create index(:recordings, :status)
  end
end
