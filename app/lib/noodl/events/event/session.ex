defmodule Noodl.Events.Event.Session do
  @moduledoc ~S"""
  Manages individual event sessions
  """
  # https://hexdocs.pm/elixir/Supervisor.html#module-restart-values-restart
  # https://hexdocs.pm/elixir/Supervisor.html#module-exit-reasons-and-restarts
  use GenServer, restart: :transient

  require Logger

  import NoodlWeb.SessionView, only: [within_allowed_time?: 2]

  alias Noodl.Events
  alias Noodl.Events.Event.Registry
  alias Noodl.Events.Event.Supervisor, as: SessionSupervisor
  alias NoodlWeb.Endpoint

  @recording Application.get_env(:noodl, :recording_client)

  # Client Functions
  def initialize(session) do
    if not within_allowed_time?(session, Timex.now(session.event.timezone)) do
      nil
    else
      case Registry.lookup(session) do
        {:ok, {pid, _session}} ->
          pid

        _ ->
          {:ok, pid} = SessionSupervisor.start_child(__MODULE__, %{session: session})

          pid
      end
    end
  end

  def ready(pid) do
    GenServer.cast(pid, {:status, "ready"})
  end

  def connected(pid) do
    GenServer.cast(pid, {:status, "connected"})
  end

  def starting(pid) do
    GenServer.cast(pid, {:status, "starting"})
  end

  def disconnected(pid) do
    GenServer.cast(pid, {:status, "disconnected"})
  end

  def ended(pid) do
    GenServer.cast(pid, {:status, "ended"})
  end

  def add_presenter(pid, %{"id" => id, "role" => role}) when role == :host do
    GenServer.cast(pid, {:add_presenter, id})
  end

  def add_presenter(_, _), do: {:error, :unauthorized}

  def remove_presenter(pid, %{"id" => id, "role" => role}) when role == :host do
    GenServer.cast(pid, {:remove_presenter, id})
  end

  def remove_presenter(_, _), do: {:error, :unauthorized}

  def mounted(nil, session),
    do: %{
      time_elapsed: zero_time(),
      time_left: calculate_time_left(session),
      presenters: MapSet.new()
    }

  def mounted(pid, _) do
    GenServer.call(pid, :mounted)
  end

  # Server Functions

  @impl true
  def handle_call(:mounted, _from, state) do
    {:reply, state |> Map.take([:time_elapsed, :time_left, :presenters]), state}
  end

  @impl true
  def handle_cast({:status, "connected" = status}, %{session: session} = state) do
    # when the stream is connected mark it as recording
    channel_name = channel(session)

    with {:ok, %{"resourceId" => rid}} <- @recording.acquire(channel_name),
         {:ok, %{"sid" => sid}} <-
           if(session.type == "video_conference",
             do: @recording.start_grid(session.id, channel_name, rid),
             else: @recording.start_pip(session.id, channel_name, rid)
           ),
         {:ok, _recording} <-
           Events.create_recording(%Events.Recording{}, %{
             "session_id" => session.id,
             "external_id" => sid,
             "resource_id" => rid
           }),
         {:ok, _session} <- status_update(session.id, status) do
      {:noreply, %{state | status: status}}
    else
      e ->
        Logger.error(inspect(e))
        {:noreply, %{state | status: status}}
    end
  end

  @impl true
  def handle_cast({:status, "ended" = status}, state) do
    Process.exit(self(), :normal)

    {:noreply, %{state | status: status}}
  end

  @impl true
  def handle_cast({:add_presenter, user}, %{presenters: presenters, session: session} = state) do
    new_presenters = MapSet.put(presenters, user)

    if MapSet.size(new_presenters) > 17 do
      Endpoint.broadcast_from!(self(), channel(session), "session_error", %{
        message: "Maximum number of presenters reached"
      })

      {:noreply, state}
    else
      Endpoint.broadcast_from!(self(), channel(session), "added_presenter", %{
        presenter: user,
        presenters: new_presenters
      })

      {:noreply, %{state | presenters: new_presenters}}
    end
  end

  @impl true
  def handle_cast({:remove_presenter, user}, %{presenters: presenters, session: session} = state) do
    new_presenters = MapSet.delete(presenters, user)

    Endpoint.broadcast_from!(self(), channel(session), "removed_presenter", %{
      presenter: user,
      presenters: new_presenters
    })

    {:noreply, %{state | presenters: new_presenters}}
  end

  @impl true
  def handle_cast(
        {:status, status},
        %{session: %{id: session_id}} = state
      ) do
    {:ok, _session} = status_update(session_id, status)

    {:noreply, %{state | status: status}}
  end

  defp status_update(session_id, status) do
    session =
      Events.get_session_by!(%{id: session_id}, [
        :host,
        event: [:sessions]
      ])

    session_activity = %{
      user_id: session.host_id,
      session_id: session.id,
      content: "Status for session #{session.name} has updated to: #{status}."
    }

    {:ok, %{session_activity: sa, session: updated_session}} =
      Events.update_session_with_activity(
        session,
        session.event,
        %{status: status},
        session_activity
      )

    sa = Events.correct_timezone(sa, :inserted_at, session.event)

    Endpoint.broadcast_from!(self(), channel(session), "status", %{
      activity: sa,
      status: status,
      session: updated_session,
      time_elapsed: zero_time()
    })

    {:ok, session}
  end

  @impl true
  def handle_info(:tick, %{session: session} = state) do
    # If we're 10 minutes over kill the session
    tz = session.event.timezone
    now = Timex.now(tz)

    end_time =
      Events.appropriate_timezone(session.end_datetime, tz, tz) |> Timex.shift(minutes: 10)

    diff =
      Timex.diff(
        now,
        end_time
      )

    if diff > 0 do
      handle_cast({:status, "ended"}, state)
      {:noreply, %{state | status: "ended"}}
    else
      next_state =
        state
        |> Map.put(:time_elapsed, Time.add(state.time_elapsed, 5))
        |> Map.put(:time_left, calculate_time_left(session))

      {:noreply, next_state}
    end
  end

  def handle_info({:EXIT, _from, reason}, state) do
    {:stop, reason, state}
  end

  defp calculate_time_left(session) do
    tz = session.event.timezone

    time = Events.appropriate_timezone(session.end_datetime, tz, tz)
    now = Events.appropriate_timezone(Timex.now(), tz, tz)

    time_left =
      Timex.diff(
        time,
        now,
        :seconds
      )

    Timex.shift(~N[2000-01-01 00:00:00], seconds: time_left)
  end

  @impl true
  def init(state) do
    # Register the process globally
    {:ok, _registry} = Registry.register(state.session)

    {:ok, ticker} = :timer.send_interval(:timer.seconds(1), self(), :tick)

    state =
      state
      |> Map.put(:ticker, ticker)
      |> Map.put(:status, "initialized")
      |> Map.put(:presenters, MapSet.new())

    Process.flag(:trap_exit, true)

    {:ok, state}
  end

  # handle termination
  @impl true
  def terminate(_reason, state) do
    cleanup(state)
    state
  end

  defp cleanup(%{session: %{event: event} = session}) do
    Logger.info("Ending session #{event.slug} - #{session.slug}")

    with {:ok, recording} <- Events.get_recording_by(session_id: session.id),
         _ <-
           @recording.stop(channel(session), recording.resource_id, recording.external_id),
         {:ok, session} <-
           status_update(session.id, "ended") do
      Logger.info("Ending session #{event.slug} - #{session.slug}")
    else
      e ->
        Logger.error("Issue shutting down session #{session.id}: #{inspect(e)}")
    end
  end

  def start_link(_, %{session: session}) do
    # Register the PID for this session
    GenServer.start_link(__MODULE__, %{
      session: session,
      time_elapsed: zero_time(),
      time_left: calculate_time_left(session),
      presenters: MapSet.new()
    })
  end

  defp zero_time() do
    {:ok, time} = Time.new(0, 0, 0)
    time
  end

  defp channel(session), do: "session:#{session.id}"
end
