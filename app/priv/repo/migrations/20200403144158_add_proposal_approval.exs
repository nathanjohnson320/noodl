defmodule Noodl.Repo.Migrations.AddProposalApproval do
  use Ecto.Migration

  def change do
    alter table(:proposals) do
      add :approved, :boolean
    end
  end
end
