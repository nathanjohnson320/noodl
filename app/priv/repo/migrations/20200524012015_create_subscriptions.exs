defmodule Noodl.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :email, :string
      add :unsubscribed, :boolean, default: false, null: false

      timestamps()
    end

    create index(:subscriptions, :email)
    create index(:subscriptions, :type)

    create unique_index(:subscriptions, [:email, :type])
  end
end
