defmodule Noodl.Repo.Migrations.DropSessionPresenters do
  use Ecto.Migration

  def up do
    drop unique_index(:session_presenters, [:user_id, :session_id])

    drop table(:session_presenters)
  end

  def down do
    create table(:session_presenters) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :session_id, references(:sessions, on_delete: :delete_all, type: :binary_id)
    end

    create unique_index(:session_presenters, [:user_id, :session_id])
  end
end
