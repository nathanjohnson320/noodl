defmodule Behaviours.AgoraClientBehavior do
  @moduledoc false

  @callback acquire(String.t()) :: tuple()
  @callback start_pip(String.t(), String.t(), String.t()) :: tuple()
  @callback start_grid(String.t(), String.t(), String.t()) :: tuple()
  @callback stop(String.t(), String.t(), String.t()) :: tuple()
end
