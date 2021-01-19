defmodule NoodlWeb.Live.Events.Manage.Sponsors do
  @moduledoc ~S"""
  LiveView for the session manage page.
  """
  use NoodlWeb, :live_view

  alias NoodlWeb.SponsorsView
  alias NoodlWeb.Router.Helpers, as: Routes

  alias Noodl.{Events, Image}
  alias Noodl.Events.Sponsor

  def mount(_params, %{"event" => event, "user" => user}, socket) do
    event = Events.get_event_by!(slug: event)
    sponsor = %Sponsor{event_id: event.id}

    sponsors = Events.list_sponsors_by_event(event.id)

    changeset = Sponsor.changeset(sponsor, %{})

    {:ok,
     socket
     |> assign(
       edited: nil,
       opened: nil,
       edited_sponsor: nil,
       sponsors: sponsors,
       sponsor: sponsor,
       changeset: changeset,
       editing: false,
       modal_open: false,
       user: user,
       validating: false,
       event: event
     )
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  def handle_event("open_popover", %{"id" => id}, socket) do
    {:noreply, assign(socket, opened: id)}
  end

  def handle_event("close_popover", _params, socket) do
    {:noreply, assign(socket, opened: nil)}
  end

  def handle_event(
        "new",
        _,
        %{assigns: %{event: event}} = socket
      ) do
    sponsor = %Sponsor{event_id: event.id}
    changeset = Sponsor.changeset(sponsor, %{})

    {:noreply,
     assign(socket,
       changeset: changeset,
       sponsor: sponsor,
       opened: nil,
       editing: false,
       modal_open: true
     )}
  end

  def handle_event(
        "edit",
        %{"id" => id},
        socket
      ) do
    sponsor = Events.get_sponsor!(id)

    {:noreply,
     assign(socket,
       changeset: Sponsor.changeset(sponsor, %{}),
       sponsor: sponsor,
       opened: nil,
       modal_open: true,
       editing: true
     )}
  end

  def handle_event(
        "validate",
        %{"sponsor" => sponsor_params},
        %{assigns: %{sponsor: sponsor}} = socket
      ) do
    updated_changeset = Sponsor.changeset(sponsor, sponsor_params)

    {:noreply, assign(socket, validating: true, changeset: updated_changeset)}
  end

  def handle_event(
        "cancel",
        _,
        socket
      ) do
    {:noreply, assign(socket, modal_open: false, opened: nil)}
  end

  def handle_event(
        "submit",
        %{"sponsor" => sponsor_params},
        %{assigns: %{event: event, sponsor: sponsor, editing: editing?}} = socket
      ) do
    insert_or_update = if editing?, do: &Events.update_sponsor/3, else: &Events.create_sponsor/3

    case insert_or_update.(sponsor, sponsor_params, fn sponsor ->
           consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
             Events.update_sponsor_photo(sponsor, path, entry)
           end)
           |> Image.all_ok?(sponsor)
         end) do
      {:ok, _} ->
        {:noreply,
         socket
         |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :sponsors))}

      {:error, :sponsor, changeset, _} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("remove_image", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:image, ref)}
  end

  def handle_event(
        "delete",
        %{"id" => id},
        %{assigns: %{event: event}} = socket
      ) do
    sponsor = Events.get_sponsor!(id)

    case Events.delete_sponsor(sponsor) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sponsor successfully deleted!")
         |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :sponsors))}
    end
  end

  def action_menu(assigns) do
    ~L"""
    <span class="sr-only">Action Menu for sponsor <%= @sponsor.name %></span>
    <svg class="w-5 h-5 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
      <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z"></path>
    </svg>
    """
  end

  defdelegate sponsor_photo_url(a), to: SponsorsView
end
