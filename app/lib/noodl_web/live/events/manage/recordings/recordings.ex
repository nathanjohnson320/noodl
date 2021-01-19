defmodule NoodlWeb.Live.Events.Manage.Recordings do
  @moduledoc ~S"""
  LiveView for the session recordings.
  """
  use NoodlWeb, :live_view

  alias Noodl.Events
  alias Noodl.Events.Transcoder
  alias Noodl.Events.Recording

  @impl true
  def mount(_params, %{"event" => event, "user" => user}, socket) do
    sessions =
      event
      |> Events.list_sessions_for_event([:recordings])

    {:ok,
     assign(socket,
       sessions: sessions,
       event: event,
       user: user,
       show_add_modal: false,
       changeset: Recording.changeset(%Recording{}, %{}),
       types: ["youtube"]
     )}
  end

  @impl true
  def handle_event("new", _, socket) do
    {:noreply,
     socket |> assign(show_add_modal: true, changeset: Recording.changeset(%Recording{}, %{}))}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply,
     socket
     |> assign(show_add_modal: false)}
  end

  @impl true
  def handle_event("recording_change", %{"recording" => params}, socket) do
    {:noreply,
     socket
     |> assign(changeset: Recording.changeset(%Recording{}, params))}
  end

  @impl true
  def handle_event(
        "recording_submit",
        %{"recording" => params},
        %{assigns: %{event: event}} = socket
      ) do
    case Events.create_recording(%Recording{}, params) do
      {:ok, _recording} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Recording saved!"
         )
         |> push_redirect(
           to: Routes.live_path(socket, Live.Events.Manage, event.slug, :recordings)
         )}
    end
  end

  @impl true
  def handle_event(
        "convert",
        %{"id" => id, "user-id" => user_id},
        %{assigns: %{event: event}} = socket
      ) do
    recording = Events.get_recording!(id)

    if is_nil(recording.status) do
      :ok = Transcoder.transcode(recording, user_id)

      {:noreply,
       socket
       |> put_flash(
         :info,
         "Recording conversion has begun. You'll receive a notification when it is complete."
       )
       |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :recordings))}
    else
      {:noreply,
       socket
       |> put_flash(:error, "This recording is already in process of being converted.")
       |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :recordings))}
    end
  end

  def date_in_exp_time(datetime, event) do
    date = Timex.to_datetime(datetime, event.timezone)
    Timex.format!(date, "%b %d, %Y", :strftime)
  end

  defdelegate recording_url(r), to: Noodl.Events
end
