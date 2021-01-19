defmodule NoodlWeb.Live.Accounts.Profile do
  @moduledoc ~S"""
  LiveView for the accounts profile page.
  """
  use NoodlWeb, :live_view

  alias Noodl.{Accounts, Image}
  alias Noodl.Accounts.User
  alias NoodlWeb.AccountsView
  alias NoodlWeb.Endpoint

  @stripe_client_id System.get_env("STRIPE_CLIENT_ID")

  def mount(_params, session, socket) do
    %{assigns: %{user: user}} = socket = Authentication.assign_user(socket, session)

    {:ok,
     socket
     |> assign(
       user: user,
       changeset: User.update_changeset(user, %{}),
       validating: false,
       state: Phoenix.Token.sign(Endpoint, "noodl stripe salt", user.id)
     )
     |> allow_upload(:profile_photo, accept: ~w(.jpg .jpeg .png))}
  end

  def handle_event(
        "validate",
        %{"user" => user_params},
        %{assigns: %{user: user}} = socket
      ) do
    changeset = User.update_changeset(user, user_params)

    {:noreply, assign(socket, validating: true, changeset: changeset)}
  end

  def handle_event(
        "submit",
        %{"user" => user_params},
        %{assigns: %{user: user}} = socket
      ) do
    case Accounts.update_user(user, user_params, fn user ->
           consume_uploaded_entries(socket, :profile_photo, fn %{path: path}, entry ->
             Accounts.update_profile_photo(user, path, entry)
           end)
           |> Image.all_ok?(user)
         end) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile successfully updated!")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("delete_account", _, %{assigns: %{user: user}} = socket) do
    case Accounts.delete_user(user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account deleted!")
         |> push_redirect(to: Routes.accounts_path(socket, :logout))}

      e ->
        IO.inspect(e)
    end
  end

  def handle_event("remove_image", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:profile_photo, ref)}
  end

  def stripe_connect_url(state, email) do
    "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=#{@stripe_client_id}&state=#{
      state
    }&scope=read_write&suggested_capabilities[]=transfers&stripe_user[email]=#{email}"
  end

  defdelegate profile_photo_url(user), to: AccountsView
end
