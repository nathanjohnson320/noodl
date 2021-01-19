defmodule Noodl.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def up do
    create table(:topics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :topic, :string
      add :parent_id, references(:topics, on_delete: :nothing, type: :binary_id)
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:topics, [:parent_id])
    create index(:topics, [:event_id])
    create unique_index(:topics, [:topic])
  end

  def down do
    drop unique_index(:topics, [:topic])
    drop index(:topics, [:parent_id])
    drop index(:topics, [:event_id])

    drop table(:topics)
  end
end
