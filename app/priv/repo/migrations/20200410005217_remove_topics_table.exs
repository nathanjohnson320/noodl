defmodule Noodl.Repo.Migrations.RemoveTopicsTable do
  use Ecto.Migration

  def change do
    drop table(:topics)
  end
end
