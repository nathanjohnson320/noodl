defmodule API.RecordingLocal do
  @behaviour Behaviours.AgoraClientBehavior

  def acquire(_channel) do
    {:ok, %{"resourceId" => UUID.uuid4()}}
  end

  def start_pip(_session_id, _channel_name, _rid) do
    {:ok, %{"sid" => UUID.uuid4()}}
  end

  def start_grid(_session_id, _channel_name, _rid) do
    {:ok, %{"sid" => UUID.uuid4()}}
  end

  def stop(_channel, _resource_id, _external_id) do
    {:ok, %{"id" => UUID.uuid4()}}
  end
end
