defmodule Noodl.Newsletters do
  @moduledoc """
  The Messaging context.
  """

  import Ecto.Query, warn: false
  alias Noodl.Repo

  alias Noodl.Newsletters.NewsletterUser

  @doc """
  Returns the list of newsletter users.

  ## Examples

      iex> list_newsletter_users()
      [%NewsletterUser{}, ...]

  """
  def list_newsletter_users do
    Repo.all(NewsletterUser)
  end

  @doc """
  Creates a newsletter user.

  ## Examples

      iex> create_newsletter_user(%{email: "foo@gmail.com"})
      %NewsletterUser{}

  """
  def create_newsletter_user(attrs \\ %{}) do
    %NewsletterUser{}
    |> NewsletterUser.changeset(attrs)
    |> Repo.insert()
  end
end
