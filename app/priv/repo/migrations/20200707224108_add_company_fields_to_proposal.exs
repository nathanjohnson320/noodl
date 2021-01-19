defmodule Noodl.Repo.Migrations.AddCompanyFieldsToProposal do
  use Ecto.Migration

  def change do
    alter table(:proposals) do
      add :company_description, :string
      add :company_name, :string
    end
  end
end
