defmodule Popover do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
      <div class="relative flex-shrink-0" phx-hook="Popover" data-open="<%= @is_open %>">
        <div>
          <button
            phx-click="toggle_popover"
            phx-target="<%= @myself %>"
            type="button"
            class="<%= @button_classes %>"
          >
            <%= @button_content %>
          </button>
        </div>

        <%= if @is_open do %>
          <%= render_block(@inner_block, assigns) %>
        <% end %>
      </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, is_open: false)}
  end

  def handle_event("toggle_popover", _params, %{assigns: %{is_open: is_open}} = socket) do
    {:noreply, assign(socket, is_open: not is_open)}
  end

  def handle_event("close_popover", _params, socket) do
    {:noreply, assign(socket, is_open: false)}
  end
end
