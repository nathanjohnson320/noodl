defmodule Noodl.Repo.Migrations.CreateGroupMessages do
  use Ecto.Migration

  def change do
    create table(:group_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :group_id, references(:groups, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:group_messages, [:user_id])
    create index(:group_messages, [:group_id])
  end
end
