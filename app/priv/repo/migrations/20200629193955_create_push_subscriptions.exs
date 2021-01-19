defmodule Noodl.Repo.Migrations.CreatePushSubscriptions do
  use Ecto.Migration

  def change do
    create table(:push_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :endpoint, :string
      add :private_key, :string
      add :public_key, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:push_subscriptions, [:user_id])
    create index(:push_subscriptions, [:private_key, :public_key])
    create unique_index(:push_subscriptions, [:endpoint, :private_key, :public_key])

    alter table(:subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
    end
  end
end
