defmodule Noodl.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :text
      add :start_datetime, :naive_datetime
      add :end_datetime, :naive_datetime
      add :is_recurring, :boolean
      add :website, :string
      add :phone, :string
      add :language, :string
      add :timezone, :string
      add :image_url, :string
      add :is_public, :boolean

      add :creator_id, references(:users, on_delete: :nilify_all, type: :binary_id)

      timestamps()
    end
  end
end
