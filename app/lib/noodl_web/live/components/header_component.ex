defmodule HeaderComponent do
  use NoodlWeb, :live_component

  alias NoodlWeb.Live
  alias NoodlWeb.Router.Helpers, as: Routes

  def mount(socket) do
    {:ok, assign(socket, is_open: false)}
  end

  def handle_event(
        "toggle",
        _,
        %{assigns: %{is_open: is_open}} = socket
      ) do
    {:noreply, assign(socket, is_open: !is_open)}
  end

  def handle_event("submit", %{"search" => %{"name" => name}}, socket) do
    {:noreply,
     push_redirect(socket,
       to: Routes.events_index_path(socket, :index, search: name)
     )}
  end

  def handle_event("notification", _params, socket) do
    {:noreply,
     push_redirect(socket,
       to: Routes.live_path(socket, Live.Accounts.Notifications)
     )}
  end

  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> redirect(to: Routes.accounts_path(socket, :logout))}
  end

  def categories_button(assigns) do
    ~L"""
    <span>Categories</span>
    """
  end

  def profile_button(assigns) do
    ~L"""
    <img
      class="object-cover w-8 h-8 rounded-full"
      src="<%= NoodlWeb.AccountsView.profile_photo_url(@user) %>"
      alt="Profile Image"
    />
    """
  end
  defdelegate profile_photo_url(user), to: NoodlWeb.AccountsView
end
