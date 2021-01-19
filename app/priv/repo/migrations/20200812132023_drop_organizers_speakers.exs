defmodule Noodl.Repo.Migrations.DropOrganizersSpeakers do
  use Ecto.Migration

  alias Noodl.Repo
  alias Noodl.Accounts.Role

  defp now(), do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  def change do
    alter table(:users) do
      add :social_link, :string
      add :social_username, :string
    end

    drop table(:events_organizers)
    drop table(:speakers)

    Repo.insert_all(Role, [
      [
        name: "organizer",
        description: "Ability to modify the event from the manage pages",
        inserted_at: now(),
        updated_at: now()
      ],
      [
        name: "speaker",
        description: "Selectable as a host during session creation",
        inserted_at: now(),
        updated_at: now()
      ],
      [
        name: "moderator",
        description: "Mute/Ban permissions in chat",
        inserted_at: now(),
        updated_at: now()
      ],
      [
        name: "presenter",
        description: "Ability to speak and screenshare during a Video Conference session",
        inserted_at: now(),
        updated_at: now()
      ],
      [
        name: "creator",
        description: "Creator of an event. Not editable, not transferrable",
        inserted_at: now(),
        updated_at: now()
      ]
    ])
  end
end
