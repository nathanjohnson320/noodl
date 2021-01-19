defmodule Noodl.Repo.Migrations.CreateFeedback do
  use Ecto.Migration

  def change do
    create table(:feedback, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subject, :string
      add :type, :string
      add :description, :text
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:feedback, [:user_id])
  end
end
