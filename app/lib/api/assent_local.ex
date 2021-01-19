defmodule TestProvider do
  @behaviour Assent.Strategy

  @spec authorize_url(Keyword.t()) :: {:ok, %{url: binary()}} | {:error, term()}
  def authorize_url(_config) do
    {:ok, %{url: ""}}
  end

  @spec callback(Keyword.t(), map()) :: {:ok, %{user: map(), token: map()}} | {:error, term()}
  def callback(_config, _params) do
    {:ok, %{user: %{}, token: %{}}}
  end
end
