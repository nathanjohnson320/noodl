defmodule Noodl.Repo.Migrations.AddProposalDeadline do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :proposal_deadline, :naive_datetime
    end
  end
end
