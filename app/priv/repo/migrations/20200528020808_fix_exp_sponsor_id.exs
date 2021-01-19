defmodule Noodl.Repo.Migrations.FixExpSponsorId do
  use Ecto.Migration

  def up do
    drop_if_exists table(:events_sponsors)

    create table(:events_sponsors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sponsor_id, references(:sponsors, on_delete: :delete_all, type: :binary_id)
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)
    end
  end

  def down do
    drop_if_exists table(:events_sponsors)

    create table(:events_sponsors) do
      add :sponsor_id, references(:sponsors, on_delete: :delete_all, type: :binary_id)
      add :event_id, references(:events, on_delete: :delete_all, type: :binary_id)
    end
  end
end
