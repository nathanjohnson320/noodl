defmodule NoodlWeb.Live.Accounts.ForgotPassword do
  @moduledoc ~S"""
  LiveView for the forgot password page.
  """
  use NoodlWeb, :bare_view

  alias Noodl.Accounts
  alias Noodl.Accounts.User
  alias Noodl.Emails.Mailer
  alias NoodlWeb.Email

  @timeout :timer.seconds(5)

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       changeset: Accounts.User.forgot_password_changeset(%User{}, %{}),
       validating: false,
       reset_locked: false,
       message: ""
     )}
  end

  def handle_event("validate", %{"user" => user}, socket) do
    {:noreply, assign(socket, changeset: User.login_changeset(%User{}, user), validating: true)}
  end

  def handle_event(
        "submit",
        %{"user" => %{"email" => email}},
        %{assigns: %{reset_locked: false}} = socket
      ) do
    # If someone resets password, don't let them fire it again for another 3 seconds
    # so they can't spam emails or tokens to figure out our secret
    Process.send_after(self(), :reset_available, @timeout)

    case Accounts.get_user_by(email: email) do
      {:ok, user} ->
        message = user |> Email.forgot_password()
        Mailer.send_now(user.email, "account", message)

      _ ->
        false
    end

    {:noreply,
     socket |> put_flash(:info, "Password reset email sent.") |> assign(reset_locked: true)}
  end

  def handle_event("submit", _, socket),
    do: {:noreply, socket |> put_flash(:info, "Wait a few seconds to try again.")}

  def handle_info(:reset_available, socket) do
    {:noreply, socket |> clear_flash(:info) |> assign(reset_locked: false)}
  end
end
