defmodule NoodlWeb.AccountsControllerTest do
  use NoodlWeb.ConnCase
  use Bamboo.Test

  import Noodl.Factory

  alias Noodl.Accounts
  alias NoodlWeb.Live

  describe "sign_up" do
    test "GET /sign-up", %{conn: conn} do
      conn = get(conn, Routes.accounts_sign_up_path(conn, :sign_up))
      assert html_response(conn, 200) =~ "Sign Up"
    end

    test "POST /sign-up should error on invalid user", %{conn: conn} do
      conn =
        post(
          conn,
          Routes.accounts_path(conn, :sign_up, %{
            "user" => %{
              "email" => "test@test.com",
              "password" => "testing",
              "password_confirmation" => "bad"
            }
          })
        )

      assert get_flash(conn, :error) =~ "Invalid user"
    end

    test "POST /sign-up should redirect home on valid user with flash for email confirmation", %{
      conn: conn
    } do
      conn =
        post(
          conn,
          Routes.accounts_path(conn, :sign_up, %{
            "user" => %{
              "lastname" => "testerson",
              "firstname" => "test",
              "email" => "test@test.com",
              "password" => "testing",
              "password_confirmation" => "testing"
            }
          })
        )

      assert redirected_to(conn) == Routes.live_path(conn, Live.Accounts.Profile)
      assert get_flash(conn, :info) =~ "Account created, check your email for confirmation"
    end

    test "POST /sign-up should send confirmation email", %{
      conn: conn
    } do
      post(
        conn,
        Routes.accounts_path(conn, :sign_up, %{
          "user" => %{
            "firstname" => "test",
            "lastname" => "testerson",
            "email" => "test@test.com",
            "password" => "testing",
            "password_confirmation" => "testing"
          }
        })
      )

      assert_email_delivered_with(
        html_body: ~r/account\/confirmation\?token=/,
        subject: "Noodl Confirmation"
      )
    end
  end

  describe "confirmation" do
    test "valid phoenix token redirects to home with success", %{conn: conn} do
      user = insert(:user)

      refute user.confirmed

      conn =
        get(
          conn,
          Routes.accounts_path(conn, :confirmation,
            token: Phoenix.Token.sign(NoodlWeb.Endpoint, "noodl confirmation", user.id)
          )
        )

      assert get_flash(conn, :info) =~ "Account confirmed"
      assert Accounts.get_user!(user.id).confirmed
    end

    test "invalid phoenix token 403s", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.accounts_path(conn, :confirmation, token: "Garbage")
        )

      assert conn.status == 403
    end
  end

  describe "password_reset" do
    test "valid phoenix token displays change form", %{conn: conn} do
      user = insert(:user)

      conn =
        get(
          conn,
          Routes.live_path(conn, Live.Accounts.PasswordReset,
            token: Phoenix.Token.sign(NoodlWeb.Endpoint, "noodl reset password", user.id)
          )
        )

      assert html_response(conn, 200) =~ "Reset your Password"
    end

    test "invalid phoenix token 403s", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.live_path(conn, Live.Accounts.PasswordReset, token: "Garbage")
        )

      assert conn.status == 302
    end
  end

  describe "login" do
    test "GET /login", %{conn: conn} do
      conn = get(conn, Routes.accounts_path(conn, :login))
      assert html_response(conn, 200) =~ "Login"
    end

    test "POST /login should error on non-existant user", %{conn: conn} do
      conn =
        post(
          conn,
          Routes.accounts_path(conn, :login, %{
            "user" => %{"email" => "test@test.com", "password" => "testing"}
          })
        )

      assert get_flash(conn, :error) =~ "Invalid login information"
    end

    test "POST /login should error on invalid password", %{conn: conn} do
      {:ok, %{user: user}} =
        Accounts.create_user(%{
          "firstname" => "Cabbage",
          "lastname" => "Patch",
          "email" => "test@test.com",
          "password" => "cabbage",
          "password_confirmation" => "cabbage"
        })

      conn =
        post(
          conn,
          Routes.accounts_path(conn, :login, %{
            "user" => %{"email" => user.email, "password" => "not cabbage"}
          })
        )

      assert get_flash(conn, :error) =~ "Invalid login information"
      assert html_response(conn, 200) =~ "Invalid login information"
    end

    test "POST /login should redirect to / on valid password", %{conn: conn} do
      {:ok, %{user: user}} =
        Accounts.create_user(%{
          "firstname" => "Cabbage",
          "lastname" => "Patch",
          "email" => "test@test.com",
          "password" => "cabbage",
          "password_confirmation" => "cabbage"
        })

      Accounts.update_user(user, %{"confirmed" => true})

      conn =
        post(
          conn,
          Routes.accounts_path(conn, :login, %{
            "user" => %{"email" => user.email, "password" => user.password}
          })
        )

      assert redirected_to(conn) == Routes.live_path(conn, Live.Pages.Index)
    end

    test "POST /login should set user id on session for successful login", %{conn: conn} do
      {:ok, %{user: user}} =
        Accounts.create_user(%{
          "firstname" => "Cabbage",
          "lastname" => "Patch",
          "email" => "test@test.com",
          "password" => "cabbage",
          "password_confirmation" => "cabbage"
        })

      Accounts.update_user(user, %{"confirmed" => true})

      conn =
        post(
          conn,
          Routes.accounts_path(conn, :login, %{
            "user" => %{"email" => user.email, "password" => user.password}
          })
        )

      assert get_session(conn, :user) == user.id
    end
  end

  describe "logout" do
    test "GET /logout" do
      user = insert(:user)

      conn =
        session_conn()
        |> put_session(:user, user.id)

      conn = conn |> get(Routes.accounts_path(conn, :logout))

      assert redirected_to(conn) == Routes.live_path(conn, Live.Pages.Index)
      assert is_nil(get_session(conn, :user))
    end
  end
end
