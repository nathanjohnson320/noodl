defmodule NoodlWeb.Live.Events.Manage.Proposals do
  @moduledoc ~S"""
  LiveView for the proposal manage page.
  """
  use NoodlWeb, :live_view

  alias Noodl.Events.Session
  alias Noodl.Events
  alias NoodlWeb.{AccountsView, EventsView}

  def mount(_params, %{"user" => user, "event" => event}, socket) do
    event = Events.get_event_by!(slug: event)
    proposals = Events.list_proposals_for_event(event)

    session = %Session{
      event_id: event.id,
      start_datetime: event.start_datetime,
      end_datetime: event.end_datetime
    }

    changeset = Session.changeset(session, event, %{})

    {:ok,
     assign(socket,
       changeset: changeset,
       session: session,
       event: event,
       user: user,
       proposals: proposals,
       expanded: nil,
       creating: false,
       validating: false
     )}
  end

  def handle_event(
        "decision",
        %{"approval" => approval, "id" => id},
        %{
          assigns: %{
            proposals: proposals
          }
        } = socket
      )
      when approval in ["yes", "no"] do
    current_proposal = Enum.find(proposals, &(&1.id == id))
    {:ok, proposal} = Events.approve_or_deny_proposal(current_proposal, approval)

    {:noreply,
     socket
     |> assign(proposals: Enum.map(proposals, &if(&1.id == proposal.id, do: proposal, else: &1)))}
  end

  def handle_event("toggle", %{"id" => id}, %{assigns: %{expanded: expanded}} = socket) do
    updated = if id == expanded, do: nil, else: id

    {:noreply, assign(socket, expanded: updated)}
  end

  def handle_event(
        "decision",
        _,
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"session" => session_params},
        %{assigns: %{event: event}} = socket
      ) do
    updated_changeset = Session.changeset(%Session{}, event, session_params)

    {:noreply, assign(socket, validating: true, changeset: updated_changeset)}
  end

  def handle_event(
        "cancel",
        _,
        socket
      ) do
    {:noreply, assign(socket, creating: false)}
  end

  def handle_event(
        "submit",
        %{"session" => %{"auto_generate_speaker" => auto_generate_speaker} = session_params},
        %{assigns: %{event: event, session: session}} = socket
      ) do
    session_params =
      if auto_generate_speaker != "false" do
        Map.put(session_params, "speaker", %{
          event_id: event.id,
          user_id: session.host_id,
          firstname: session.host.firstname,
          lastname: session.host.lastname,
          email: session.host.email
        })
      else
        session_params
      end

    case Events.create_session(session, event, session_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Proposal session #{session_params["name"]} created successfully!"
         )
         |> push_redirect(
           to: Routes.live_path(socket, Live.Events.Manage, event.slug, :schedule)
         )}

      {:error, :session, %Ecto.Changeset{} = changeset, _} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, :speaker, _, _} ->
        {:noreply, socket |> put_flash(:error, "This speaker already exists!")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:invalid_time, msg} ->
        {:noreply, socket |> put_flash(:error, msg)}
    end
  end

  def handle_event(
        "create-session",
        %{"id" => id},
        %{
          assigns: %{
            session: session,
            proposals: proposals,
            event: event
          }
        } = socket
      ) do
    current_proposal = Enum.find(proposals, &(&1.id == id))

    session = %{session | host: current_proposal.user}

    changeset =
      Session.changeset(session, event, %{
        audience: current_proposal.audience,
        description: current_proposal.description,
        end_datetime: event.end_datetime,
        event_id: event.id,
        host_id: current_proposal.user.id,
        name: current_proposal.title,
        proposal_id: current_proposal.id,
        start_datetime: event.start_datetime,
        topic: current_proposal.topic
      })

    {:noreply,
     assign(socket, session: session, creating: true, changeset: changeset, validating: true)}
  end

  defdelegate profile_photo_url(a), to: AccountsView
  defdelegate pretty_manage_date(a, b), to: EventsView
end
