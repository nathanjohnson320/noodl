defmodule Noodl.Repo.Migrations.CreateNewsletterUser do
  use Ecto.Migration

  def change do
    create table(:newsletter_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :active, :boolean, default: true, null: false
      add :email, :string

      timestamps()
    end
  end
end
