defmodule NoodlWeb.Live.Events.Proposal.New do
  @moduledoc ~S"""
  LiveView for the proposal new page.
  """
  use NoodlWeb, :live_view

  alias Noodl.Events
  alias Noodl.Events.Proposal

  def mount(%{"id" => id}, session, socket) do
    %{assigns: %{user: user}} = socket = Authentication.assign_user(socket, session)
    event = Events.get_event_by!(slug: id)
    proposal = %Proposal{user_id: user.id, event_id: event.id}
    changeset = Events.change_proposal(proposal)

    {:ok,
     assign(socket,
       changeset: changeset,
       proposal: proposal,
       validating: false,
       event: event
     )}
  end

  def handle_event(
        "validate",
        %{"proposal" => proposal_params},
        %{assigns: %{proposal: proposal}} = socket
      ) do
    {:noreply,
     assign(socket, changeset: Proposal.changeset(proposal, proposal_params), validating: true)}
  end

  def handle_event(
        "submit",
        %{"proposal" => proposal_params},
        %{assigns: %{event: _event, proposal: proposal}} = socket
      ) do
    case Events.create_proposal(proposal, proposal_params) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> put_flash(:info, "Proposal created successfully.")
         |> push_redirect(to: Routes.live_path(socket, Live.Pages.Index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
