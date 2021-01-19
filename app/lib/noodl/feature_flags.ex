defmodule FeatureFlags do
  @valid_flags [
    :feedback_modal,
    :direct_messaging
  ]

  def enabled?(flag) do
    flag in @valid_flags || raise "FeatureFlag #{inspect(flag)} is not defined."

    if Mix.env() == :dev do
      true
    else
      enabled =
        :noodl
        |> Application.get_env(__MODULE__, [])
        |> Keyword.get(:enabled)
        |> List.wrap()

      flag in enabled
    end
  end

  def when_enabled(flag, default \\ nil, fun) when is_function(fun, 0) do
    if enabled?(flag) do
      fun.()
    else
      default
    end
  end
end
