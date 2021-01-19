defmodule Noodl.Repo.Migrations.CreateSpeakers do
  use Ecto.Migration

  def change do
    create table(:speakers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :firstname, :string
      add :lastname, :string
      add :email, :string
      add :social_link, :string
      add :social_username, :string

      add :event_id, references(:events, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:speakers, [:event_id])
    create index(:speakers, [:user_id])
    create index(:speakers, [:email])
  end
end
