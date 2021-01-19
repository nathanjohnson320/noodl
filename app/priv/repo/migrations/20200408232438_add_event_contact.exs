defmodule Noodl.Repo.Migrations.AddEventContact do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :contact_phone, :string
      add :contact_email, :string
    end
  end
end
