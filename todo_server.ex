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
  # Client Stuff

  def start() do
    pid = spawn(fn -> loop(TodoList.new()) end)
    Process.register(pid, :todo_server)
  end

  def add_entry(entry) do
    send(:todo_server, {:add_entry, entry})
    :ok
  end

  def entries(date) do
    send(:todo_server, {:entries, self(), date})

    receive do
      {:todo_entries, entries} -> entries
    after
      5000 -> {:error, :timeout}
    end
  end

  def update_entry(entry) do
    send(:todo_server, {:update_entry, entry})
    :ok
  end

  def delete_entry(entry_id) do
    send(:todo_server, {:delete_entry, entry_id})
    :ok
  end

  # Server stuff

  def loop(todo_list) do
    new_todo_list =
      receive do
        message -> proccess_message(todo_list, message)
      end

    loop(new_todo_list)
  end

  defp proccess_message(todo_list, {:add_entry, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp proccess_message(todo_list, {:entries, caller, date}) do
    send(caller, {:todo_entries, TodoList.entries(todo_list, date)})

    todo_list
  end

  defp proccess_message(todo_list, {:update_entry, entry}) do
    TodoList.update_entry(todo_list, entry)
  end

  defp proccess_message(todo_list, {:delete_entry, entry_id}) do
    TodoList.delete_entry(todo_list, entry_id)
  end
end
