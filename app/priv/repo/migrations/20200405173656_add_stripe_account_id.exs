defmodule Noodl.Repo.Migrations.AddStripeAccountId do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stripe_account, :string
    end
  end
end
