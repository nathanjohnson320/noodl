defmodule Noodl.Repo.Migrations.RemoveEventSponsors do
  use Ecto.Migration

  def change do
    drop table(:events_sponsors)

    alter table(:sponsors) do
      add :external_link, :string, size: 512
      add :link_text, :string, size: 512
    end
  end
end
