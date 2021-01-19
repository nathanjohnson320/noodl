defmodule NoodlWeb.EventsController do
  use NoodlWeb, :controller

  alias Phoenix.LiveView

  alias Noodl.Events
  alias NoodlWeb.Live.Events, as: LiveEvents

  @bucket System.get_env("AWS_S3_BUCKET", "")

  def payment(%{assigns: %{user: user}} = conn, %{
        "stripe_token" => token,
        "payment" => %{"stripe_intent" => payment_intent}
      }) do
    case Stripe.PaymentIntent.confirm(payment_intent, %{
           payment_method_data: %{type: "card", card: %{token: token}}
         }) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Event successfully purchased!")
        |> redirect(to: Routes.live_path(conn, Live.Pages.Index))

      _ ->
        conn
        |> put_flash(:error, "An error occurred while purchasing event.")
        |> LiveView.Controller.live_render(LiveEvents.New,
          session: %{
            "user" => user
          }
        )
    end
  end

  def calendar(conn, %{"id" => event_slug, "session" => session_slug}) do
    event = Events.get_event_by!(slug: event_slug)

    [slug: session_slug, event_id: event.id]
    |> Events.get_session_by([:host])
    |> case do
      {:ok, session} ->
        events = [
          %ICalendar.Event{
            summary: session.name,
            description: "Talk by #{session.host.firstname} #{session.host.lastname}",
            dtstart: Events.appropriate_timezone(session.start_datetime, event.timezone),
            location:
              NoodlWeb.Endpoint.url() <>
                Routes.events_session_dashboard_path(
                  conn,
                  :dashboard,
                  event_slug,
                  session_slug
                )
          }
        ]

        conn
        |> put_resp_content_type("text/calendar")
        |> send_resp(
          200,
          %ICalendar{events: events}
          |> ICalendar.to_ics()
        )

      _ ->
        conn |> send_resp(404, "")
    end
  end

  def calendar(conn, %{"id" => id}) do
    [slug: id]
    |> Events.get_event_by()
    |> case do
      {:ok, event} ->
        events = [
          %ICalendar.Event{
            summary: event.name,
            description: event.description,
            dtstart: Events.appropriate_timezone(event.start_datetime, event.timezone),
            location:
              NoodlWeb.Endpoint.url() <>
                Routes.events_show_path(conn, :show, event.slug)
          }
        ]

        conn
        |> put_resp_content_type("text/calendar")
        |> send_resp(
          200,
          %ICalendar{events: events}
          |> ICalendar.to_ics()
        )

      _ ->
        conn |> send_resp(404, "")
    end
  end

  def download_recording(conn, %{"recording_id" => recording_id}) do
    recording = Events.get_recording!(recording_id)

    conn =
      conn
      |> put_resp_header("content-type", "video/mp4")
      |> put_resp_header("content-disposition", "attachment; filename=video.mp4")
      |> send_chunked(200)

    {:ok, url} =
      ExAws.Config.new(:s3)
      |> ExAws.S3.presigned_url(:get, @bucket, Events.download_path(recording))

    img_stream = API.HTTPStream.get(url)

    Enum.reduce_while(img_stream, conn, fn chunk, conn ->
      case Plug.Conn.chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end)
  end
end
