defmodule Noodl.Repo.Migrations.AddTemporaryStream do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :stream_id, :string
    end
  end
end
