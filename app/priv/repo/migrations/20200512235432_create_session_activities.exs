defmodule Noodl.Repo.Migrations.CreateSessionActivities do
  use Ecto.Migration

  def change do
    create table(:session_activities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :session_id, references(:sessions, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end
  end
end
