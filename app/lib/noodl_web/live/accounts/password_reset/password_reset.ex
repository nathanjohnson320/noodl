defmodule NoodlWeb.Live.Accounts.PasswordReset do
  @moduledoc ~S"""
  LiveView for the password reset page.
  """
  use NoodlWeb, :bare_view

  alias Noodl.Accounts
  alias Noodl.Accounts.User
  alias NoodlWeb.Endpoint

  @max_age 86_400

  def mount(%{"token" => token}, _session, socket) do
    with {:ok, user_id} <-
           Phoenix.Token.verify(Endpoint, "noodl reset password", token,
             max_age: round(@max_age / 24)
           ),
         {:ok, user} <- Accounts.get_user(user_id) do
      {:ok,
       assign(socket,
         user: user,
         changeset: User.password_reset_changeset(user, %{}),
         validating: false
       )}
    else
      _e ->
        {:ok,
         socket
         |> put_flash(:error, "Unable to verify token.")
         |> push_redirect(to: Routes.live_path(socket, Live.Pages.Index))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, %{assigns: %{user: user}} = socket) do
    {:noreply,
     assign(socket, changeset: User.password_reset_changeset(user, user_params), validating: true)}
  end

  def handle_event(
        "submit",
        %{"user" => user_params},
        %{assigns: %{user: user}} = socket
      ) do
    case Accounts.password_reset(user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password changed successfully.")
         |> push_redirect(to: Routes.live_path(socket, Live.Pages.Index))}

      {:error, changeset} ->
        {:ok, socket |> assign(changeset: changeset)}
    end
  end
end
