defmodule Noodl.Repo.Migrations.AgoraRecordings do
  use Ecto.Migration

  def change do
    rename table(:recordings), :mux_id, to: :external_id
    rename table(:recordings), :playback_id, to: :resource_id

    create index(:recordings, :external_id)

    flush()

    alter table(:recordings) do
      modify :resource_id, :string, size: 512
    end
  end
end
