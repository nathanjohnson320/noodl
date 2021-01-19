defmodule Noodl.Newsletters.NewsletterUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "newsletter_users" do
    field :active, :boolean, default: true
    field :email, :string

    timestamps()
  end

  @doc false
  def changeset(newsletter_user, attrs) do
    newsletter_user
    |> cast(attrs, [:active, :email])
    |> validate_required([:active, :email])
    |> unique_constraint(:email, message: "Email is invalid")
  end
end
