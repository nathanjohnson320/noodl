defmodule Noodl.Repo.Migrations.EventBans do
  use Ecto.Migration

  def change do
    create table(:event_bans, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end
  end
end
