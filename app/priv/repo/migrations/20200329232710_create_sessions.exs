defmodule Noodl.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :topic, :string
      add :audience, :string
      add :live_stream_id, :string
      add :recording_url, :string
      add :start_datetime, :naive_datetime
      add :end_datetime, :naive_datetime
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)
      add :host_id, references(:users, on_delete: :nilify_all, type: :binary_id)

      timestamps()
    end

    create index(:sessions, [:event_id])
    create index(:sessions, [:host_id])
  end
end
