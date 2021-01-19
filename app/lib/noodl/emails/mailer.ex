defmodule Noodl.Emails.Mailer do
  use Bamboo.Mailer, otp_app: :noodl

  alias __MODULE__
  alias Noodl.Accounts

  def send_now(email, type, message) do
    with false <- Accounts.is_unsubscribed?(email, type),
         %Bamboo.Email{} = message <- Mailer.deliver_now(message) do
      {:ok, message}
    else
      true -> {:error, "Unsubscribed"}
      e -> {:error, e}
    end
  end
end
