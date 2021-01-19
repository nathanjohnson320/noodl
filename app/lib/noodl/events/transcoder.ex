defmodule Noodl.Events.Transcoder do
  @moduledoc ~S"""
  Converts hls files to mp4 async.
  """
  use GenServer

  require Logger

  alias ExAws.S3
  alias Noodl.Events
  alias Noodl.Notifications
  alias Noodl.Repo

  @bucket System.get_env("AWS_S3_BUCKET", "")
  @chunk_size 5 * 1024 * 1024

  # Client Functions
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: Transcoder)
  end

  def transcode(recording, user_id) do
    GenServer.cast(Transcoder, {:transcode, recording, user_id})
  end

  # Server functions
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:transcode, recording, user_id}, state) do
    recording = Repo.preload(recording, :session)
    # convert the file to mp4 in the background, start with an initiation
    %{
      body: %{
        bucket: bucket,
        key: key,
        upload_id: upload_id
      }
    } =
      S3.initiate_multipart_upload(
        @bucket,
        "recordings/#{String.replace(recording.session_id, "-", "")}/#{recording.external_id}_session:#{
          recording.session_id
        }.mp4",
        content_type: "video/mp4"
      )
      |> ExAws.request!()

    try do
      {:ok, _recording} = Events.update_recording(recording, %{"status" => "converting"})

      # Do some sorcery to convert with low memory the URL of the hls playlist into
      # an mp4 file through streams
      porc =
        Porcelain.spawn_shell(
          "ffmpeg -hide_banner -loglevel panic -i #{Events.recording_url(recording)} -f mp4 -movflags frag_keyframe+empty_moov pipe:",
          out: :stream
        )

      # Split the chunks of binary data into 5mb payloads
      parts =
        porc.out
        |> Stream.map(fn chunk ->
          :binary.bin_to_list(chunk)
        end)
        |> Stream.concat()
        |> Stream.chunk_every(@chunk_size)
        |> Stream.with_index()
        # For each chunk upload that part with an index and store that index with the etag
        |> Stream.map(fn {chunk, index} ->
          # add one to index because it's 1..10,000 not 0
          index = index + 1

          %{headers: headers} =
            S3.upload_part(bucket, key, upload_id, index, :binary.list_to_bin(chunk))
            |> ExAws.request!()

          # Have to decode the value of ETag because reasons unknown
          {index,
           Enum.find_value(headers, fn {k, v} -> if k == "ETag", do: v end) |> Jason.decode!()}
        end)
        |> Enum.to_list()

      # with all the etag/index pairs we can call complete to mark the upload as done
      S3.complete_multipart_upload(
        bucket,
        key,
        upload_id,
        parts
      )
      |> ExAws.request!()

      # Push a notification to the original user
      with {:ok, _} <-
             Notifications.create_notification(%{
               "user_id" => user_id,
               "content" => "Recording for \"#{recording.session.name}\" is complete!"
             }),
           {:ok, _recording} <-
             Events.update_recording(recording, %{"status" => "converted"}) do
        Logger.info("Finished encoding #{recording.id}")
      else
        e -> Logger.error("Failed to update recording #{inspect(e)}")
      end
    catch
      _, _ ->
        # ALWAYS abort if there's an error. Otherwise this will leave hanging uploads which don't show
        Logger.error("Failed to transcode #{recording.id}, #{key}, #{upload_id}")
        S3.abort_multipart_upload(bucket, key, upload_id) |> ExAws.request!()
    end

    {:noreply, state}
  end
end
