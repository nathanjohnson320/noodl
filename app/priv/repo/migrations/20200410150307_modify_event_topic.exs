defmodule Noodl.Repo.Migrations.ModifyEventTopic do
  use Ecto.Migration

  def up do
    drop index(:events, [:topics])

    alter table(:events) do
      add(:topic, :string)
      remove :topics
    end
  end

  def down do
    alter table(:events) do
      remove :topic

      add :topics, {:array, :string}
    end

    create index(:events, [:topics])
  end
end
