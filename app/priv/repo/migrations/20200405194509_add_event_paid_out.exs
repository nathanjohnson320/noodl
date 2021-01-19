defmodule Noodl.Repo.Migrations.AddEventPaidOut do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :paid_out, :boolean, default: false
    end

    create index(:events, [:paid_out])
  end
end
