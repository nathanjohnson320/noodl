defmodule API.Recording do
  @moduledoc """
  Agora cloud recording implementation
  https://docs.agora.io/en/cloud-recording/restfulapi/
  """

  alias Agora.AccessKey, as: Agora

  @base_url "https://api.agora.io"
  @recording_uid "4000000000"
  @app_id Application.get_env(:noodl, :agora_app_id, "")
  @certificate Application.get_env(:noodl, :agora_certificate, "")
  @bucket System.get_env("AWS_S3_BUCKET", "")
  @api_user System.get_env("AGORA_API_USER", "")
  @api_secret System.get_env("AGORA_API_SECRET", "")
  @access_key System.get_env("AWS_ACCESS_KEY_ID", "")
  @secret_key System.get_env("AWS_SECRET_ACCESS_KEY", "")

  defp base(uri, params) do
    url = "#{@base_url}/v1/apps/#{@app_id}/cloud_recording#{uri}"

    credentials = Base.encode64(@api_user <> ":" <> @api_secret)

    case Mojito.post(
           url,
           [
             {"Authorization", "Basic #{credentials}"},
             {"Content-Type", "application/json"}
           ],
           Jason.encode!(params)
         ) do
      {:ok, %Mojito.Response{status_code: 200, body: body}} ->
        Jason.decode(body)

      {:ok, %Mojito.Response{status_code: 201}} ->
        {:ok, nil}

      {:ok, %Mojito.Response{status_code: 206}} ->
        {:error, :no_users_in_channel}

      {:ok, %Mojito.Response{status_code: 400, body: body}} ->
        IO.inspect(body)
        {:error, :invalid_request}

      {:ok, %Mojito.Response{status_code: 401}} ->
        {:error, :unauthorized}

      {:ok, %Mojito.Response{status_code: 404, body: body}} ->
        IO.inspect(body)
        {:error, :resource_not_found}

      {:ok, %Mojito.Response{status_code: 500}} ->
        {:error, :server_error}

      {:ok, %Mojito.Response{status_code: 504}} ->
        {:error, :timeout}

      _ ->
        {:error, :unknown}
    end
  end

  def acquire(channel_name) do
    base(
      "/acquire",
      %{
        "cname" => channel_name,
        "uid" => @recording_uid,
        "clientRequest" => %{
          resourceExpiredHour: 24
        }
      }
    )
  end

  def start_pip(session_id, channel_name, resource_id) do
    token =
      Agora.new_token(@app_id, @certificate, channel_name, @recording_uid, [
        :join_channel,
        :publish_video,
        :publish_audio,
        :publish_data
      ])

    base(
      "/resourceid/#{resource_id}/mode/mix/start",
      %{
        "cname" => channel_name,
        "uid" => @recording_uid,
        "clientRequest" => %{
          "token" => token,
          "recordingConfig" => %{
            "maxIdleTime" => 120,
            "transcodingConfig" => %{
              "width" => 1920,
              "height" => 1080,
              "fps" => 60,
              "bitrate" => 4780,
              "mixedVideoLayout" => 3,
              "layoutConfig" => [
                %{
                  # Primary
                  "uid" => "1",
                  "x_axis" => 0.0,
                  "y_axis" => 0.0,
                  "width" => 1.0,
                  "height" => 1.0,
                  # Fit mode, vs 0 cropped
                  "render_mode" => 1
                },
                %{
                  # Secondary
                  "uid" => "2",
                  "x_axis" => 0.8,
                  "y_axis" => 0.8,
                  "width" => 0.2,
                  "height" => 0.18,
                  # Fit mode, vs 0 cropped
                  "render_mode" => 1
                }
              ]
            }
          },
          "storageConfig" => %{
            "vendor" => 1,
            "region" => 0,
            "bucket" => @bucket,
            "accessKey" => @access_key,
            "secretKey" => @secret_key,
            "fileNamePrefix" => [
              "recordings",
              String.replace(session_id, "-", "")
            ]
          }
        }
      }
    )
  end

  def start_grid(session_id, channel_name, resource_id) do
    token =
      Agora.new_token(@app_id, @certificate, channel_name, @recording_uid, [
        :join_channel,
        :publish_video,
        :publish_audio,
        :publish_data
      ])

    base(
      "/resourceid/#{resource_id}/mode/mix/start",
      %{
        "cname" => channel_name,
        "uid" => @recording_uid,
        "clientRequest" => %{
          "token" => token,
          "recordingConfig" => %{
            "maxIdleTime" => 120,
            "transcodingConfig" => %{
              "width" => 1920,
              "height" => 1080,
              "fps" => 60,
              "bitrate" => 4780,
              # Best Fit Layout
              # The number of columns and rows and the grid
              # size vary depending on the number of users in
              # the channel. This layout supports up to 17 users.
              "mixedVideoLayout" => 1
            }
          },
          "storageConfig" => %{
            "vendor" => 1,
            "region" => 0,
            "bucket" => @bucket,
            "accessKey" => @access_key,
            "secretKey" => @secret_key,
            "fileNamePrefix" => [
              "recordings",
              String.replace(session_id, "-", "")
            ]
          }
        }
      }
    )
  end

  def stop(channel_name, resource_id, recording_id) do
    base("/resourceid/#{resource_id}/sid/#{recording_id}/mode/mix/stop", %{
      "cname" => channel_name,
      "uid" => @recording_uid,
      "clientRequest" => %{}
    })
  end
end
