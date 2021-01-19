defmodule FeedbackModal do
  use Phoenix.LiveView

  alias Noodl.Accounts
  alias Noodl.Accounts.Feedback
  alias NoodlWeb.LayoutView

  def render(%{user: user} = assigns) when not is_nil(user),
    do: LayoutView.render("feedback_modal.html", assigns)

  def render(assigns), do: LayoutView.render("empty.html", assigns)

  def mount(_params, %{"user" => user}, socket) when not is_nil(user) do
    {:ok,
     socket
     |> assign(
       open: false,
       validating: false,
       submitted: false,
       user: user,
       changeset: Accounts.change_feedback(%Feedback{user_id: user.id})
     )}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       open: false,
       validating: false,
       submitted: false,
       user: nil,
       changeset: Accounts.change_feedback(%Feedback{})
     )}
  end

  def handle_event("toggle_open", _, %{assigns: %{open: open}} = socket) do
    {:noreply, socket |> assign(open: not open)}
  end

  def handle_event("validate", %{"feedback" => feedback}, %{assigns: %{user: user}} = socket) do
    {:noreply,
     assign(socket,
       changeset: Feedback.changeset(%Feedback{user_id: user.id}, feedback),
       validating: true
     )}
  end

  def handle_event("reset", _, socket) do
    {:noreply,
     assign(socket,
       validating: false,
       submitted: false,
       changeset: Accounts.change_feedback(%Feedback{})
     )}
  end

  def handle_event("close", _, socket) do
    {:noreply,
     assign(socket,
       open: false,
       validating: false,
       submitted: false,
       changeset: Accounts.change_feedback(%Feedback{})
     )}
  end

  def handle_event(
        "submit",
        %{"feedback" => feedback},
        %{assigns: %{user: user}} = socket
      ) do
    case Accounts.create_feedback(%Feedback{user_id: user.id}, feedback) do
      {:ok, _feedback} ->
        {:noreply, socket |> assign(submitted: true)}

      {:error, changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end
end
