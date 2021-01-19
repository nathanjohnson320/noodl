defmodule Noodl.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :content, :text
      add :is_read, :boolean
      add :priority, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:priority])
  end
end
