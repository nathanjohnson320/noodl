defmodule Noodl.Repo.Migrations.AddSessionType do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :type, :string, default: "keynote"
    end
  end
end
