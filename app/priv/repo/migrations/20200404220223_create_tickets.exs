defmodule Noodl.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :code, :string
      add :expires_at, :naive_datetime
      add :paid, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nilify_all, type: :binary_id)
      add :release_id, references(:releases, on_delete: :delete_all, type: :binary_id)
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:tickets, [:user_id])
    create index(:tickets, [:release_id])
    create index(:tickets, [:event_id])
  end
end
