defmodule Noodl.Repo.Migrations.CreateProposals do
  use Ecto.Migration

  def change do
    create table(:proposals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :topic, :string
      add :audience, :string
      add :description, :text
      add :notes, :text
      add :tags, {:array, :string}
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:proposals, [:event_id])
    create index(:proposals, [:user_id])
  end
end
