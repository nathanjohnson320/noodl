defmodule Noodl.Repo.Migrations.CreateRefunds do
  use Ecto.Migration

  def change do
    create table(:refunds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :charge_id, :string
      add :stripe_id, :string
      add :amount, :integer
      add :status, :string
      add :ticket_id, references(:tickets, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:refunds, [:ticket_id])

    alter table(:tickets) do
      add :charge_id, :string
    end
  end
end
