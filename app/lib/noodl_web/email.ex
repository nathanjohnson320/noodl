defmodule NoodlWeb.Email do
  use Bamboo.Phoenix, view: NoodlWeb.EmailView

  alias Phoenix.Token
  alias NoodlWeb.Endpoint
  alias NoodlWeb.LayoutView

  @user Application.get_env(:noodl, Noodl.Emails.Mailer, username: "no-reply")
        |> Keyword.get(:username)

  def confirmation(user) do
    base()
    |> to(user.email)
    |> subject("Noodl Confirmation")
    |> render(:confirmation,
      user: user,
      token: Token.sign(Endpoint, "noodl confirmation", user.id)
    )
  end

  def weekly_summary(user, events) do
    base()
    |> to(user.email)
    |> subject("Noodl This Week")
    |> render(:weekly_summary,
      user: user,
      events: events
    )
  end

  def forgot_password(user) do
    base()
    |> to(user.email)
    |> subject("Noodl Password Reset")
    |> render(:password_reset,
      user: user,
      token: Token.sign(Endpoint, "noodl reset password", user.id)
    )
  end

  def base() do
    new_email()
    |> from(@user)
    |> put_html_layout({LayoutView, "email.html"})
    |> put_text_layout({LayoutView, "email.text"})
  end
end
