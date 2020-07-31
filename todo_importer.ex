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

defmodule TodoList.CsvImporter do
  def import(csv_path) do
    File.stream!(csv_path)
    |> Stream.map(&String.replace(&1, "\n", ""))
    |> Stream.map(&String.split(&1, ","))
    |> Stream.map(&parse_line/1)
    |> Enum.map(&convert_to_entry/1)
    |> TodoList.new()
  end

  defp parse_line([date, title]) do
    [year, month, date] =
      date
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)

    {{year, month, date}, String.trim(title)}
  end

  defp convert_to_entry({{year, month, date}, title}) do
    {:ok, date} = Date.new(year, month, date)

    %{date: date, title: title}
  end
end
