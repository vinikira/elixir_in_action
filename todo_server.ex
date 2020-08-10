defmodule TodoList do
  defstruct auto_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %__MODULE__{},
      fn entry, todo_list ->
        add_entry(todo_list, entry)
      end
    )
  end

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)

    new_entries = Map.put(todo_list.entries, todo_list.auto_id, entry)

    %__MODULE__{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Stream.filter(fn {_, entry} ->
      entry.date == date
    end)
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def update_entry(todo_list, entry_id, updater_func) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        old_entry_id = old_entry.id
        new_entry = %{id: ^old_entry_id} = updater_func.(old_entry)

        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)

        %__MODULE__{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, id) do
    new_entries = Map.delete(todo_list.entries, id)

    %__MODULE__{todo_list | entries: new_entries}
  end
end

defmodule TodoServer do
  use GenServer

  # Client stuff

  def start() do
    GenServer.start(__MODULE__, TodoList.new(), name: __MODULE__)
  end

  def add_entry(entry) do
    GenServer.cast(__MODULE__, {:add_entry, entry})
  end

  def entries(date) do
    GenServer.call(__MODULE__, {:entries, date})
  end

  def update_entry(entry) do
    GenServer.cast(__MODULE__, {:update_entry, entry})
  end

  def delete_entry(entry_id) do
    GenServer.cast(__MODULE__, {:delete_entry, entry_id})
  end

  # Server stuff

  @impl GenServer
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, todo_list) do
    new_todo_list = TodoList.add_entry(todo_list, entry)

    {:noreply, new_todo_list}
  end

  @impl GenServer
  def handle_cast({:update_entry, entry}, todo_list) do
    new_todo_list = TodoList.update_entry(todo_list, entry)

    {:noreply, new_todo_list}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, todo_list) do
    new_todo_list = TodoList.delete_entry(todo_list, entry_id)

    {:noreply, new_todo_list}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, todo_list) do
    entries = TodoList.entries(todo_list, date)

    {:reply, entries, todo_list}
  end
end
