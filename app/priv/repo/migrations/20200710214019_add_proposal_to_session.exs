defmodule Noodl.Repo.Migrations.AddProposalToSession do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :proposal_id, references(:proposals, on_delete: :nothing, type: :binary_id)
    end
  end
end
