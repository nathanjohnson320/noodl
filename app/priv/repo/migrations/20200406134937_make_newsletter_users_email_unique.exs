defmodule Noodl.Repo.Migrations.MakeNewsletterUsersEmailUnique do
  use Ecto.Migration

  def change do
    create unique_index(:newsletter_users, [:email])
  end
end
