defmodule NoodlWeb.Live.Events.Index do
  @moduledoc ~S"""
  LiveView for the event index page.
  """
  use NoodlWeb, :live_view

  alias NoodlWeb.EventsView
  alias Noodl.Events

  @default_offset 0
  @default_exp_limit 10
  @default_filters %{
    topic: "",
    timezone: "",
    language: ""
  }

  def mount(params, session, socket) do
    socket = Authentication.assign_user(socket, session)

    {_, socket} = init(params, socket)
    {:ok, socket}
  end

  def handle_params(params, _, socket), do: init(params, socket)

  defp init(params, socket) do
    search = params["search"]
    topic = params["topic"]
    user = socket.assigns.user

    new_filters = if topic, do: Map.put(@default_filters, :topic, topic), else: @default_filters

    events =
      Events.list_events_by_search(
        search,
        @default_exp_limit,
        @default_offset,
        new_filters
      )

    {:noreply,
     assign(socket,
       topic: topic,
       filters: new_filters,
       limit: @default_exp_limit,
       offset: @default_offset,
       count: events |> Enum.count(),
       events: events,
       user: user,
       search: search,
       show_more: false
     )}
  end

  def handle_event(
        "toggle_topic_list",
        _params,
        %{assigns: %{show_more: show_more}} = socket
      ) do
    {:noreply, assign(socket, show_more: not show_more)}
  end

  def handle_event("search", %{"search" => %{"search" => search}}, socket) do
    init(%{"search" => if(search != "", do: search), "topic" => socket.assigns[:topic]}, socket)
  end

  def handle_event(
        "paginate_up",
        _params,
        %{assigns: %{offset: offset, limit: limit, filters: filters} = assigns} = socket
      ) do
    search = assigns[:search]
    new_offset = offset + limit

    events = Events.list_events_by_search(search, limit, new_offset, filters)

    {:noreply, assign(socket, events: events, offset: new_offset)}
  end

  def handle_event(
        "paginate_down",
        _params,
        %{assigns: %{offset: offset, limit: limit, filters: filters} = assigns} = socket
      ) do
    search = assigns[:search]
    new_offset = offset - limit

    events = Events.list_events_by_search(search, limit, new_offset, filters)

    {:noreply, assign(socket, events: events, offset: new_offset)}
  end

  def handle_event(
        "filter_select",
        %{"_target" => [_, "topic" = topic], "filter" => filter},
        %{assigns: %{filters: filters} = assigns} = socket
      ) do
    search = assigns[:search]
    current_topic = Map.get(filter, topic)

    new_filters = Map.put(filters, :topic, current_topic)

    events =
      Events.list_events_by_search(
        search,
        @default_exp_limit,
        @default_offset,
        new_filters
      )

    {:noreply,
     assign(socket,
       filters: new_filters,
       current_topic: current_topic,
       events: events,
       offset: @default_offset,
       limit: @default_exp_limit,
       count: Enum.count(events)
     )}
  end

  def handle_event(
        "filter_select",
        %{"_target" => [_, "language" = language], "filter" => filter},
        %{
          assigns: %{search: search, filters: filters}
        } = socket
      ) do
    current_language = Map.get(filter, language)
    new_filters = Map.put(filters, :language, current_language)

    events =
      Events.list_events_by_search(
        search,
        @default_exp_limit,
        @default_offset,
        new_filters
      )

    {:noreply,
     assign(socket,
       events: events,
       offset: @default_offset,
       limit: @default_exp_limit,
       count: Enum.count(events),
       filters: new_filters
     )}
  end

  def handle_event(
        "filter_select",
        %{"_target" => [_, "timezone" = timezone], "filter" => filter},
        %{
          assigns: %{search: search, filters: filters}
        } = socket
      ) do
    current_timezone = Map.get(filter, timezone)
    new_filters = Map.put(filters, :timezone, current_timezone)

    events =
      Events.list_events_by_search(
        search,
        @default_exp_limit,
        @default_offset,
        new_filters
      )

    {:noreply,
     assign(socket,
       filters: new_filters,
       events: events,
       offset: @default_offset,
       limit: @default_exp_limit,
       count: Enum.count(events)
     )}
  end

  def handle_event("filter_select", _, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "clear",
        _params,
        socket
      ) do
    events =
      Events.list_events_by_search(
        nil,
        @default_exp_limit,
        @default_offset,
        @default_filters
      )

    {:noreply,
     socket
     |> assign(show_more: false, filters: @default_filters, search: nil, events: events)
     |> push_patch(to: Routes.events_index_path(socket, :index))}
  end

  def pagination_text(%{count: 0}) do
    "Oops! No results found."
  end

  def pagination_text(%{events: events, count: count, offset: offset}) do
    "Showing #{offset + 1} to #{offset + Enum.count(events)} of #{count}"
  end

  def truncate_description(desc), do: String.slice(desc, 0..120) <> "..."

  defdelegate timezones, to: EventsView
  defdelegate languages, to: EventsView
  defdelegate cover_photo_url(exp), to: EventsView
  defdelegate pretty_event_date(date, tz), to: EventsView
  defdelegate user_timezone(socket), to: EventsView
end
