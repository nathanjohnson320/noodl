defmodule Noodl.Repo.Migrations.AddEventTopics do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :topics, {:array, :string}
    end

    create index(:events, [:topics])
  end
end
