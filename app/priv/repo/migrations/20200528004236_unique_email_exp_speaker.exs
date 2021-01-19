defmodule Noodl.Repo.Migrations.UniqueEmailExpSpeaker do
  use Ecto.Migration

  def change do
    create unique_index(:speakers, [:email, :event_id])
  end
end
