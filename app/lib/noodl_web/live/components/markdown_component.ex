defmodule MarkdownComponent do
  use NoodlWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, current_tab: "write", tabs: ["write", "preview"])}
  end

  def handle_event("change_tab", %{"tab" => tab}, socket) when tab in ["write", "preview"],
    do: {:noreply, socket |> assign(current_tab: tab)}

  def handle_event("change_tab", _, socket), do: {:noreply, socket}

  def field(field) do
    field |> Atom.to_string() |> String.capitalize()
  end
end
