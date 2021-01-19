defmodule Behaviours.RecaptchaClientBehavior do
  @moduledoc false

  @callback client_id() :: String.t()
  @callback server_id() :: String.t()
  @callback validate_captcha_token(String.t()) :: tuple()
end
