defmodule Todo.Server do
  use GenServer

  # Client stuff

  def start(todo_list_name) do
    GenServer.start(__MODULE__, todo_list_name)
  end

  def add_entry(server_pid, entry) do
    GenServer.cast(server_pid, {:add_entry, entry})
  end

  def entries(server_pid, date) do
    GenServer.call(server_pid, {:entries, date})
  end

  def update_entry(server_pid, entry) do
    GenServer.cast(server_pid, {:update_entry, entry})
  end

  def delete_entry(server_pid, entry_id) do
    GenServer.cast(server_pid, {:delete_entry, entry_id})
  end

  # Server stuff

  @impl GenServer
  def init(name) do
    send(self(), :real_init)

    {:ok, name}
  end

  @impl GenServer
  def handle_info(:real_init, name) do
    {:noreply, {name, Todo.Database.get(name) || Todo.List.new()}}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, {name, todo_list}) do
    new_todo_list = Todo.List.add_entry(todo_list, entry)

    Todo.Database.store(name, new_todo_list)

    {:noreply, {name, new_todo_list}}
  end

  @impl GenServer
  def handle_cast({:update_entry, entry}, {name, todo_list}) do
    new_todo_list = Todo.List.update_entry(todo_list, entry)

    {:noreply, {name, new_todo_list}}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, {name, todo_list}) do
    new_todo_list = Todo.List.delete_entry(todo_list, entry_id)

    {:noreply, {name, new_todo_list}}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, {name, todo_list}) do
    entries = Todo.List.entries(todo_list, date)

    {:reply, entries, {name, todo_list}}
  end
end
