defmodule NoodlWeb.Live.Accounts.Security do
  @moduledoc ~S"""
  LiveView for the event security page.
  """
  use NoodlWeb, :live_view

  alias Noodl.Accounts.User
  alias Noodl.Accounts

  def mount(_params, session, socket) do
    {:ok,
     socket
     |> Authentication.assign_user(session)
     |> assign(
       changeset: User.password_reset_changeset(%User{}, %{}),
       validating: false
     )}
  end

  def handle_event("validate", %{"user" => user}, socket) do
    {:noreply,
     assign(socket, changeset: User.password_reset_changeset(%User{}, user), validating: true)}
  end

  def handle_event("submit", %{"user" => user_params}, %{assigns: %{user: user}} = socket) do
    case Accounts.password_reset(user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password changed successfully.")
         |> push_redirect(to: Routes.live_path(socket, Live.Accounts.Security))}

      {:error, changeset} ->
        {:ok, socket |> assign(changeset: changeset)}
    end
  end
end
