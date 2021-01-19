defmodule Noodl.Repo.Migrations.CreateRecordings do
  use Ecto.Migration

  def change do
    create table(:recordings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :mux_id, :string
      add :playback_id, :string
      add :session_id, references(:sessions, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:recordings, [:session_id])

    alter table(:sessions) do
      remove :recording_url, :string, default: ""
    end
  end
end
