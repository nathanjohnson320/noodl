defmodule Noodl.Repo.Migrations.AddSessionPlaybackUrl do
  use Ecto.Migration

  def up do
    alter table(:sessions) do
      add :playback_url, :string
      add :stream_key, :string
      modify :start_datetime, :utc_datetime
      modify :end_datetime, :utc_datetime
    end
  end

  def down do
    alter table(:sessions) do
      remove :playback_url, :string
      remove :stream_key, :string
      modify :start_datetime, :naive_datetime
      modify :end_datetime, :naive_datetime
    end
  end
end
