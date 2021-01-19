defmodule Noodl.Repo.Migrations.AddCoverPhoto do
  use Ecto.Migration

  def up do
    alter table(:events) do
      add :cover_photo, :string
      remove :image_url, :string
    end

    alter table(:users) do
      add :profile_photo, :string
    end
  end

  def down do
    alter table(:events) do
      remove :cover_photo, :string
      add :image_url, :string
    end

    alter table(:users) do
      remove :profile_photo
    end
  end
end
