defmodule NoodlWeb.Live.Accounts.Login do
  @moduledoc ~S"""
  LiveView for the login page.
  """
  use NoodlWeb, :bare_view

  alias Noodl.Accounts.User
  alias Noodl.MultiProvider

  def mount(_params, _session, socket) do
    {:ok, %{url: github_link}} = MultiProvider.request(:github)
    {:ok, %{url: apple_link}} = MultiProvider.request(:apple)
    {:ok, %{url: google_link}} = MultiProvider.request(:google)

    {:ok,
     assign(socket,
       changeset: User.login_changeset(%User{}, %{}),
       validating: false,
       github_link: github_link,
       apple_link: apple_link,
       google_link: google_link
     )}
  end

  def handle_event("validate", %{"user" => user}, socket) do
    {:noreply, assign(socket, changeset: User.login_changeset(%User{}, user), validating: true)}
  end
end
