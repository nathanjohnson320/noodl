defmodule Noodl.Repo.Migrations.CreateReleases do
  use Ecto.Migration

  def change do
    create table(:releases, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :default_quantity, :integer
      add :description, :string
      add :end_at, :naive_datetime
      add :max_tickets_per_person, :integer
      add :price, :integer
      add :pricing_type, :string
      add :quantity, :integer
      add :start_at, :naive_datetime
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :nilify_all, type: :binary_id)

      timestamps()
    end

    create index(:releases, [:event_id])
    create index(:releases, [:user_id])
  end
end
