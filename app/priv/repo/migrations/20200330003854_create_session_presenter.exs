defmodule Noodl.Repo.Migrations.CreateSessionPresenter do
  use Ecto.Migration

  def change do
    create table(:session_presenters) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :session_id, references(:sessions, on_delete: :delete_all, type: :binary_id)
    end

    create unique_index(:session_presenters, [:user_id, :session_id])
  end
end
