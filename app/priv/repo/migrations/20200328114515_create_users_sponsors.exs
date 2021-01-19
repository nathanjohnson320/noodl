defmodule Noodl.Repo.Migrations.CreateUsersSponsors do
  use Ecto.Migration

  def change do
    create table(:users_sponsors) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :sponsor_id, references(:sponsors, on_delete: :delete_all, type: :binary_id)
    end

    create unique_index(:users_sponsors, [:user_id, :sponsor_id])
  end
end
