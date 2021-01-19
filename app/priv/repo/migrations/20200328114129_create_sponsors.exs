defmodule Noodl.Repo.Migrations.CreateSponsors do
  use Ecto.Migration

  def change do
    create table(:sponsors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :image, :string
      add :company_info, :text

      timestamps()
    end
  end
end
