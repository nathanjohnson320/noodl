defmodule Noodl.Repo.Migrations.CreateUserRoles do
  use Ecto.Migration

  def change do
    create table(:user_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role_id, references(:roles, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:user_roles, [:role_id])
    create index(:user_roles, [:user_id])
    create index(:user_roles, [:event_id])
  end
end
