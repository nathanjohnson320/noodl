defmodule Noodl.Repo do
  use Ecto.Repo,
    otp_app: :noodl,
    adapter: Ecto.Adapters.Postgres
end
