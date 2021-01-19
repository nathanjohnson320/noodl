defmodule Noodl.MultiProvider do
  def request(provider) do
    config = config!(provider)

    config[:strategy].authorize_url(config)
  end

  def callback(provider, params, session_params \\ %{}) do
    config =
      provider
      |> config!()
      |> Assent.Config.put(:session_params, session_params)

    config[:strategy].callback(config, params)
  end

  defp config!(provider) do
    Application.get_env(:noodl, :strategies)[provider] ||
      raise "No provider configuration for #{provider}"
  end
end
