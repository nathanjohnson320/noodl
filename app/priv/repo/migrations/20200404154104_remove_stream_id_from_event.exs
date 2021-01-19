defmodule Noodl.Repo.Migrations.RemoveStreamIdFromEvent do
  use Ecto.Migration

  def up do
    alter table(:events) do
      remove :stream_id
    end
  end

  def down do
    alter table(:events) do
      add(:stream_id, :string)
    end
  end
end
