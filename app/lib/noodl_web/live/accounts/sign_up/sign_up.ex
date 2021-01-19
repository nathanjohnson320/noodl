defmodule NoodlWeb.Live.Accounts.SignUp do
  @moduledoc ~S"""
  LiveView for the sign up page.
  """
  use NoodlWeb, :bare_view

  alias Noodl.Accounts.User

  def mount(_params, session, socket) do
    changeset = session["changeset"] || User.signup_changeset(%User{}, %{})

    {:ok,
     assign(socket,
       changeset: changeset,
       validating: false
     )}
  end

  def handle_event("validate", %{"user" => user}, socket) do
    {:noreply, assign(socket, changeset: User.signup_changeset(%User{}, user), validating: true)}
  end
end
