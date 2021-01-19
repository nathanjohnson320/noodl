defmodule Noodl.Repo.Migrations.UserProposalUnique do
  use Ecto.Migration

  def change do
    create unique_index(:proposals, [:user_id, :event_id])
  end
end
