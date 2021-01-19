defmodule Noodl.Repo.Migrations.AddRecordingUserId do
  use Ecto.Migration

  alias Noodl.Accounts.User
  alias Noodl.Repo

  def up do
    alter table(:users) do
      add :recording_id, :bigserial, null: false
    end

    flush()

    users = Repo.aggregate(User, :count)

    if Mix.env() != :test do
      # Gross but: take recording IDs 1 and 2 and set them to the max
      # because agora's recording requires integer uids
      max = Repo.aggregate(User, :max, :recording_id) || 0

      if users > 1 do
        a = Repo.get_by!(User, recording_id: 1)
        b = Repo.get_by!(User, recording_id: 2)

        Repo.update!(User.changeset(a, %{"recording_id" => max + 1}))
        Repo.update!(User.changeset(b, %{"recording_id" => max + 2}))
      end

      execute "ALTER SEQUENCE users_recording_id_seq START with #{max + 3} RESTART"
    end
  end

  def down do
    alter table(:users) do
      remove :recording_id
    end
  end
end
