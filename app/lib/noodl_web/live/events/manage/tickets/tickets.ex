defmodule NoodlWeb.Live.Events.Manage.Tickets do
  @moduledoc ~S"""
  LiveView for the release edit page.
  """
  use NoodlWeb, :live_view

  alias Noodl.Events
  alias Noodl.Ticketing
  alias Noodl.Ticketing.Release
  alias NoodlWeb.EventsView

  def mount(
        _params,
        %{
          "user" => user,
          "event" => event
        },
        socket
      ) do
    event = Events.get_event_by!([slug: event], [:releases])

    {:ok,
     assign(socket,
       user: user,
       release: %Release{
         user_id: user.id,
         event_id: event.id,
         start_at: Timex.now(),
         end_at: event.end_datetime
       },
       validating: false,
       editing: false,
       show_options: false,
       event: event,
       error: ""
     )}
  end

  def handle_event(
        "new",
        _,
        %{assigns: %{event: %{releases: releases} = event}} = socket
      )
      when releases != [] do
    {:noreply,
     socket
     |> put_flash(:error, "We only support one ticket tier right now!")
     |> push_redirect(
       to: Routes.live_path(socket, Live.Events.Manage, event.slug, :tickets)
     )}
  end

  def handle_event("new", _, %{assigns: %{event: event, user: user}} = socket) do
    release = %Release{
      user_id: user.id,
      event_id: event.id,
      start_at: Timex.now(),
      end_at: event.end_datetime
    }

    {:noreply,
     socket
     |> assign(editing: true, release: release, changeset: Ticketing.change_release(release))}
  end

  def handle_event("cancel", _, %{assigns: %{release: release}} = socket) do
    {:noreply, socket |> assign(editing: false, changeset: Ticketing.change_release(release))}
  end

  def handle_event("toggle_options", _, %{assigns: %{show_options: show_options}} = socket) do
    {:noreply, socket |> assign(show_options: !show_options)}
  end

  def handle_event("edit", %{"id" => id}, %{assigns: %{event: event}} = socket) do
    release = Enum.find(event.releases, &(&1.id == id))

    {:noreply,
     socket
     |> assign(editing: true, release: release, changeset: Ticketing.change_release(release))}
  end

  def handle_event("delete", %{"id" => id}, %{assigns: %{event: event}} = socket) do
    release = Enum.find(event.releases, &(&1.id == id))

    case Ticketing.delete_release(release) do
      {:ok, _release} ->
        {:noreply,
         socket
         |> put_flash(:info, "Release deleted successfully.")
         |> push_redirect(
           to: Routes.live_path(socket, Live.Events.Manage, event.slug, :tickets)
         )}

      {:error, _, message, _} ->
        {:noreply, socket |> put_flash(:info, message)}
    end
  end

  def handle_event(
        "validate",
        %{"release" => release_params},
        %{assigns: %{release: release}} = socket
      ) do
    {:noreply,
     assign(socket, validating: true, changeset: Release.changeset(release, release_params))}
  end

  def handle_event(
        "submit",
        %{"release" => release_params},
        %{assigns: %{event: event, release: release}} = socket
      ) do
    # @TODO update when multi-release
    # Using event dates here until we roll out multi-release
    merged =
      Map.merge(release_params, %{
        "end_at" => event.end_datetime,
        "start_at" => event.start_datetime
      })

    case Ticketing.update_release(release, merged) do
      {:ok, _release} ->
        {:noreply,
         socket
         |> put_flash(:info, "Release saved successfully.")
         |> push_redirect(
           to: Routes.live_path(socket, Live.Events.Manage, event.slug, :tickets)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, :validate_total, error, _} ->
        {:noreply, assign(socket, error: error)}
    end
  end

  def action_menu(assigns) do
    ~L"""
    <span class="sr-only">Action Menu for <%= @release.title %></span>
    <svg class="w-5 h-5 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
      <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z"></path>
    </svg>
    """
  end

  defdelegate pretty_manage_date(a, b), to: EventsView
end
