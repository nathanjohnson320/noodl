defmodule Noodl.Ticketing.Cart do
  @moduledoc ~S"""
  Manages cart sessions for users via ets (or DETS if needed)
  """
  use GenServer

  # Client Functions
  def start_link(_) do
    # Name the genserver so it's accessible across nodes by a single value
    GenServer.start_link(__MODULE__, %{}, name: Cart)
  end

  def get(user) do
    try do
      GenServer.call(Cart, {:get, user.id})
    catch
      :exit, e ->
        {:error, e}
    end
  end

  def add_tickets(user, params) do
    try do
      updated_tickets = GenServer.call(Cart, {:add, user.id, params})
      {:ok, updated_tickets}
    catch
      :exit, e ->
        {:error, e}
    end
  end

  def update_tickets(user, params) do
    GenServer.call(Cart, {:update, user.id, params})
  end

  def remove_tickets(user, params) do
    GenServer.call(Cart, {:remove, user.id, params})
  end

  def empty(user) do
    GenServer.call(Cart, {:empty, user.id})
  end

  # Server Functions

  @impl true
  def init(state) do
    state =
      state
      |> Map.put(:table, :ets.new(:carts, [:set, :private]))

    {:ok, state}
  end

  @impl true
  def handle_call(
        {:add, user_id, new_tickets},
        _from,
        %{table: table} = state
      ) do
    tickets =
      case :ets.lookup(table, user_id) do
        [] ->
          :ets.insert(table, {user_id, new_tickets})
          new_tickets

        [{_user_id, tickets}] ->
          updated_tickets = Map.merge(tickets, new_tickets)
          :ets.insert(table, {user_id, updated_tickets})
          updated_tickets
      end

    {:reply, tickets, state}
  end

  @impl true
  def handle_call(
        {:get, user_id},
        _from,
        %{table: table} = state
      ) do
    response =
      case :ets.lookup(table, user_id) do
        [] ->
          {:error, :not_found}

        [{_user_id, tickets}] ->
          {:ok, tickets}
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call(
        {:remove, user_id, release_id},
        _from,
        %{table: table} = state
      ) do
    response =
      case :ets.lookup(table, user_id) do
        [] ->
          {:error, :not_found}

        [{_user_id, tickets}] ->
          updated_tickets = Map.delete(tickets, release_id)
          :ets.insert(table, {user_id, updated_tickets})
          {:ok, updated_tickets}
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call(
        {:empty, user_id},
        _from,
        %{table: table} = state
      ) do
    {:reply, :ets.delete(table, user_id), state}
  end
end
