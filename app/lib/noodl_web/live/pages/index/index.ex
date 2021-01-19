defmodule NoodlWeb.Live.Pages.Index do
  @moduledoc """
  Page LiveView
  """
  use NoodlWeb, :live_view

  alias Noodl.Newsletters
  alias Noodl.Meta
  alias NoodlWeb.LayoutView

  def mount(_params, params, socket) do
    {:ok,
     socket
     |> Authentication.assign_user(params)
     |> assign(
       meta: %Meta{
         title: "A premium live streaming platform.",
         description: "Noodl is an online marketplace for virtual events.",
         image: LayoutView.full_url(Routes.static_path(socket, "/images/noodl.png")),
         url: LayoutView.full_url(Routes.live_path(socket, __MODULE__))
       }
     )}
  end

  def handle_event("submit", %{"search" => %{"name" => name}}, socket) do
    {:noreply,
     push_redirect(socket,
       to: Routes.events_index_path(socket, :index, search: name)
     )}
  end

  def handle_event("newsletter_submit", %{"newsletter" => %{"email" => email}}, socket) do
    sub = %{email: email}

    case Newsletters.create_newsletter_user(sub) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully signed up for our newsletter!")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "An error occurred when signing up for our newsletter.")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}
    end
  end
end
