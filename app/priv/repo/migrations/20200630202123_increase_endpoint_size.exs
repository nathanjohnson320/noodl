defmodule Noodl.Repo.Migrations.IncreaseEndpointSize do
  use Ecto.Migration

  def change do
    alter table(:push_subscriptions) do
      modify :endpoint, :string, size: 512
    end
  end
end
