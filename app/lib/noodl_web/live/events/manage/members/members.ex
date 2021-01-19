defmodule NoodlWeb.Live.Events.Manage.Members do
  @moduledoc ~S"""
  LiveView for the members event page.
  """
  use NoodlWeb, :live_view

  alias Noodl.{Accounts, Events, Ticketing, Repo}
  alias NoodlWeb.AccountsView

  def mount(_params, %{"event" => id, "user" => user}, socket) do
    event = Events.get_event_by!(%{slug: id})

    members = Ticketing.list_event_members(event)

    {:ok,
     assign(socket,
       event: event,
       user: user,
       total_members: Enum.count(members),
       members: members,
       roles: Accounts.list_manageable_roles(),
       search: "",
       show_add_modal: false,
       show_role_modal: false,
       selected_user: nil,
       new_member: nil,
       new_roles: %{}
     )}
  end

  def handle_event("filter_users", %{"search" => %{"name" => name}}, socket) do
    {:noreply, socket |> assign(search: name)}
  end

  def handle_event("new", _, socket) do
    {:noreply, socket |> assign(show_add_modal: true)}
  end

  def handle_event("add_member_change", %{"member" => member}, socket) do
    {:noreply, socket |> assign(new_member: member)}
  end

  def handle_event(
        "add_member_submit",
        %{"member" => member},
        %{assigns: %{event: event}} = socket
      ) do
    with email when not is_nil(email) <- Map.get(member, "email"),
         {:ok, user} <- Accounts.get_user_by(email: email),
         {:ok, _ticket} <- Ticketing.create_admin_ticket(event, user.id) |> Repo.insert() do
      {:noreply,
       socket
       |> put_flash(:info, "#{email} has been granted a ticket!")
       |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :members))}
    else
      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "This email has not created an account yet!")
         |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :members))}
    end
  end

  def handle_event("member_change", %{"member" => roles}, socket) do
    {:noreply, socket |> assign(new_roles: roles)}
  end

  def handle_event(
        "member_submit",
        %{"member" => roles},
        %{assigns: %{selected_user: user, event: event}} = socket
      ) do
    case Accounts.update_user_roles(user, event, roles) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully updated #{get_username(user)}'s roles")
         |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :members))}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Error occurred while updating member!")
         |> push_redirect(to: Routes.live_path(socket, Live.Events.Manage, event.slug, :members))}
    end
  end

  def handle_event("edit", %{"id" => user_id}, %{assigns: %{members: members}} = socket) do
    user = Enum.find(members, &(&1.id == user_id))
    {:noreply, socket |> assign(show_role_modal: true, selected_user: user)}
  end

  def handle_event("cancel", _, socket) do
    {:noreply,
     socket
     |> assign(
       show_role_modal: false,
       show_add_modal: false,
       selected_user: nil,
       new_member: nil,
       user_roles: nil
     )}
  end

  def user_tickets(user) do
    user.tickets
    |> Enum.map(fn
      %{release: %{title: title}} ->
        title

      _ ->
        ""
    end)
    |> Enum.uniq()
    |> Enum.join(", ")
  end

  def filtered_users(users, ""), do: users

  def filtered_users(users, search) do
    search = String.downcase(search)

    Enum.filter(users, fn user ->
      firstname = (user.firstname || "") |> String.downcase()
      lastname = (user.lastname || "") |> String.downcase()
      email = String.downcase(user.email)

      String.contains?(firstname, search) || String.contains?(lastname, search) ||
        String.contains?(email, search)
    end)
  end

  def role_checked(%{user_roles: roles}, role_id, selected_roles) when is_list(roles) do
    role =
      Enum.find(roles, fn user_role ->
        user_role.role_id == role_id
      end)

    selected_role = Map.get(selected_roles, role_id)

    cond do
      not is_nil(selected_role) and selected_role == "true" ->
        true

      not is_nil(selected_role) and selected_role == "false" ->
        false

      not is_nil(role) ->
        true

      true ->
        false
    end
  end

  defdelegate profile_photo_url(a), to: AccountsView
  defdelegate get_username(a), to: NoodlWeb.SharedView
end
