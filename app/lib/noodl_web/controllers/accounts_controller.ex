defmodule NoodlWeb.AccountsController do
  use NoodlWeb, :controller

  alias Phoenix.LiveView.Controller
  alias Noodl.Accounts
  alias Noodl.Accounts.User
  alias Noodl.MultiProvider
  alias NoodlWeb.Endpoint
  alias NoodlWeb.Live.Accounts, as: LiveAccounts

  @max_age 86_400

  def sign_up(conn, %{"user" => %{"agree_terms" => "false"} = user}) do
    conn
    |> put_layout("bare.html")
    |> put_flash(:info, "Must accept terms to sign up.")
    |> Controller.live_render(LiveAccounts.SignUp,
      session: %{
        "changeset" => Accounts.User.signup_changeset(%User{}, user)
      }
    )
  end

  def sign_up(conn, %{"user" => user}) do
    with {:ok, %{user: user}} <- Accounts.create_user(user) do
      conn
      |> put_flash(:info, "Account created, check your email for confirmation.")
      |> put_session(:user, user.id)
      |> redirect(to: Routes.live_path(conn, LiveAccounts.Profile))
    else
      {:error, :user, %Ecto.Changeset{} = changeset, _} ->
        conn
        |> put_flash(:error, "Invalid user")
        |> put_layout("bare.html")
        |> Controller.live_render(LiveAccounts.SignUp,
          session: %{
            "changeset" => changeset
          }
        )

      e ->
        IO.inspect(e)

        conn
        |> put_flash(:error, "Unknown Error")
        |> put_layout("bare.html")
        |> Controller.live_render(LiveAccounts.SignUp,
          session: %{
            "changeset" => Accounts.User.signup_changeset(%User{}, %{})
          }
        )
    end
  end

  def login(conn, %{"user" => user}) do
    case Accounts.login_user(user) do
      {:ok, %{confirmed: true} = user} ->
        conn
        |> put_session(:user, user.id)
        # Doing this lets us disconnect a user globally. Like if we need to permaban
        # https://hexdocs.pm/phoenix_live_view/security-model.html#disconnecting-all-instances-of-a-given-live-user
        |> put_session(:live_socket_id, "users_socket:#{user.id}")
        |> redirect(
          to: NavigationHistory.last_path(conn) || Routes.live_path(conn, Live.Pages.Index)
        )

      {:ok, user} ->
        conn
        |> put_flash(:error, "You must confirm your account before you can sign in.")
        |> put_layout("bare.html")
        |> Controller.live_render(LiveAccounts.Login,
          session: %{
            "changeset" => Accounts.User.login_changeset(user, %{}),
            "user" => user
          }
        )

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Invalid login information")
        |> put_layout("bare.html")
        |> Controller.live_render(LiveAccounts.Login,
          session: %{
            "changeset" => changeset,
            "user" => user
          }
        )
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> delete_resp_cookie("ack")
    |> redirect(to: Routes.live_path(conn, Live.Pages.Index))
  end

  def connect(%{assigns: %{user: user}} = conn, %{"state" => state, "code" => account}) do
    # validate the incoming phoenix token
    # make sure its id is the same as the logged in person
    # update their account with the stripe account id
    with {:ok, user_id} <-
           Phoenix.Token.verify(Endpoint, "noodl stripe salt", state, max_age: @max_age),
         true <- user_id == user.id,
         {:ok, token} <- Stripe.Connect.OAuth.token(account),
         {:ok, user} <- Accounts.update_user(user, %{"stripe_account" => token.stripe_user_id}) do
      conn
      |> put_flash(:info, "Account connected.")
      |> put_session(:user, user.id)
      |> redirect(to: Routes.live_path(conn, Live.Accounts.Profile))
    else
      _ -> conn |> resp(403, "Unauthorized")
    end
  end

  def connect(conn, _params) do
    conn
    |> put_flash(:info, "Error occurred while connecting account.")
    |> redirect(to: Routes.live_path(conn, Live.Pages.Index))
  end

  def confirmation(conn, %{"token" => token}) do
    with {:ok, user_id} <-
           Phoenix.Token.verify(Endpoint, "noodl confirmation", token, max_age: @max_age * 7),
         {:ok, user} <- Accounts.get_user(user_id),
         {:ok, user} <- Accounts.update_user(user, %{"confirmed" => true}) do
      conn
      |> put_flash(:info, "Account confirmed!")
      |> put_session(:user, user.id)
      |> redirect(to: Routes.live_path(conn, Live.Accounts.Profile))
    else
      _ -> conn |> resp(403, "Unauthorized")
    end
  end

  def unsubscribe(conn, %{"token" => token}) do
    with {:ok, %{email: email, type: type}} <-
           Phoenix.Token.verify(Endpoint, "noodl unsubscribe", token),
         {:ok, _sub} <-
           Accounts.create_subscription(%{
             "email" => email,
             "type" => type,
             "unsubscribed" => true
           }) do
      conn
      |> put_flash(:info, "You are now unsubscribed!")
      |> redirect(to: Routes.live_path(conn, Live.Pages.Index))
    else
      {:error,
       %{
         errors: [
           email:
             {"has already been taken",
              [constraint: :unique, constraint_name: "subscriptions_email_type_index"]}
         ]
       }} ->
        conn
        |> put_flash(:info, "You have already unsubscribed.")
        |> redirect(to: Routes.live_path(conn, Live.Pages.Index))

      _ ->
        conn
        |> put_flash(:error, "An error occurred while unsubscribing. Please contact support.")
        |> redirect(to: Routes.live_path(conn, Live.Pages.Index))
    end
  end

  def oauth(conn, %{"provider" => provider} = params)
      when provider in ["github", "apple", "google"] do
    params = Map.delete(params, "provider")

    {:ok, %{user: %{"email" => email}}} = MultiProvider.callback(String.to_atom(provider), params)

    case Accounts.get_user_by(email: email) do
      {:ok, user} ->
        conn
        |> put_session(:user, user.id)
        |> put_session(:live_socket_id, "users_socket:#{user.id}")
        |> put_resp_cookie("ack", %{user_id: user.id}, sign: true)
        |> redirect(to: Routes.live_path(conn, LiveAccounts.Profile))

      {:error, :not_found} ->
        {:ok, %{user: user}} =
          Accounts.create_oauth_user(%{"email" => email, "confirmed" => true})

        conn
        |> put_session(:user, user.id)
        |> put_session(:live_socket_id, "users_socket:#{user.id}")
        |> redirect(to: Routes.live_path(conn, LiveAccounts.Profile))
    end
  end
end
