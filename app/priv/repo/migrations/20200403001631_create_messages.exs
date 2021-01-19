defmodule Noodl.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)
      add :session_id, references(:sessions, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:messages, [:user_id])
    create index(:messages, [:event_id])
    create index(:messages, [:session_id])
  end
end
