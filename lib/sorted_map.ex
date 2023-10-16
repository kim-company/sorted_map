defmodule SortedMap do
  @moduledoc """
  This module provides a data struct that mostly works like a map, 
  but enumerates the same was as a list where each new item is inserted 
  at the end of the list.

  This module implements the `Access` behaviour and `Collectable`, `Enumerable` and `Inspect`

  The `Access`-implementation allows for a behaves similar to the implemtation for `Map`, 
  alloqing the use of `put_in/3`, `get_in/2` and `update_in/3` and similar,

  The `Enumerable` implementation returns `{key, value}`, like a `Keyword`-list

  The `Collectable` implementation allows inserting `{key, value}`, like a `Keyword`-list.
  Duplicated keys will however be overwritten and their position stays the same.
  """

  @behaviour Access
  defstruct map: %{}, positions: []

  def new(), do: %SortedMap{}

  @doc """
  Creates a new `%SortedMap{}` from the given enumerable.

  Applies the function `fun` if given to each element. before inserting

  Note: There is no guarantee for ordering when creating a sorted map from a normal map. 
  Either use a keyword list or sort the map before inserting with `Enum.sort/2` or `Enum.sort_by/3`

  ## Examples

      iex> SortedMap.new()
      SortedMap.new([])

      iex> SortedMap.new(a: 1, b: 2)
      SortedMap.new([a: 1, b: 2])

      iex> SortedMap.new(1..3, &{&1, &1})
      SortedMap.new([{1, 1}, {2, 2}, {3, 3}])

  """
  def new(enumerable), do: enumerable |> Enum.into(%SortedMap{})
  def new(enumerable, fun), do: enumerable |> Enum.map(fun) |> Enum.into(%SortedMap{})

  @doc """
  Inserts a new or existing key-value pair into the Map.

  Inserting a new value puts it at the last position in the list. 
  Overriding an existing value does not update it's position in the list

      iex> SortedMap.put(SortedMap.new(a: 1, b: 2), :c, 3)
      SortedMap.new(a: 1, b: 2, c: 3)

      iex> SortedMap.put(SortedMap.new(a: 1, b: 2, c: 3), :b, 4)
      SortedMap.new(a: 1, b: 4, c: 3)

  """
  def put(sorted_map, key, value) do
    positions =
      if Map.has_key?(sorted_map.map, key),
        do: sorted_map.positions,
        else: sorted_map.positions ++ [key]

    map = Map.put(sorted_map.map, key, value)

    %SortedMap{sorted_map | map: map, positions: positions}
  end

  @doc """
  Inserts a new key-value pair into the Map. Same as `Map.put_new/3` or `Keyword.put_new/3`

  Inserting a new value puts it at the last position in the list. 

  Overriding an existing value does not update it's position in the list

      iex> SortedMap.put_new(SortedMap.new(a: 1, b: 2), :c, 3)
      SortedMap.new(a: 1, b: 2, c: 3)

      iex> SortedMap.put_new(SortedMap.new(a: 1, b: 2, c: 3), :b, 4)
      SortedMap.new(a: 1, b: 2, c: 3)

  """
  def put_new(sorted_map, key, value) do
    if has_key?(sorted_map, key),
      do: sorted_map,
      else: put_in(sorted_map[key], value)
  end

  @doc """
  Lazily inserts a new key-value pair into the Map. Same as `Map.put_new_lazy/3` or `Keyword.put_new_lazy/3`

  Inserting a new value puts it at the last position in the list. 
  Overriding an existing value does not update it's position in the list

      iex> SortedMap.put_new_lazy(SortedMap.new(a: 1, b: 2), :c, fn -> 3 end)
      SortedMap.new(a: 1, b: 2, c: 3)

      iex> SortedMap.put_new_lazy(SortedMap.new(a: 1, b: 2, c: 3), :b, fn -> 4 end)
      SortedMap.new(a: 1, b: 2, c: 3)

  """
  def put_new_lazy(sorted_map, key, value_fun) do
    if has_key?(sorted_map, key),
      do: sorted_map,
      else: put_in(sorted_map[key], value_fun.())
  end

  @doc """
  Returns the keys as a list, sorted by when they were inserted.

      iex> SortedMap.keys(SortedMap.new(a: 1, b: 2))
      [:a, :b]

  """
  def keys(sorted_map) do
    sorted_map.positions
  end

  @doc """
  Update an existing key or insert a new entry at the end of the map.

  Refer to `Map.update/4` for usage details.

  ## Examples

      iex> SortedMap.update(SortedMap.new(a: 1, b: 2), :a, 1, & &1 + 1)
      SortedMap.new(a: 2, b: 2)

      iex> SortedMap.update(SortedMap.new(a: 1, b: 2), :c, 1, & &1 + 1)
      SortedMap.new(a: 1, b: 2, c: 1)

  """
  def update(sorted_map, key, default, update_fun) do
    if has_key?(sorted_map, key) do
      update_in(sorted_map.map[key], update_fun)
    else
      put_in(sorted_map[key], default)
    end
  end

  @doc """
  Update an existing key of the map. Raises if the key does not exist.

  Refer to `Map.update!/3` for usage details.

  ## Examples

      iex> SortedMap.update!(SortedMap.new(a: 1, b: 2), :a, & &1 + 1)
      SortedMap.new(a: 2, b: 2)

      iex> SortedMap.update!(SortedMap.new(a: 1, b: 2), :c, & &1 + 1)
      ** (KeyError) key :c not found in: SortedMap.new([a: 1, b: 2])

  """
  def update!(sorted_map, key, update_fun) do
    if has_key?(sorted_map, key) do
      map = Map.update!(sorted_map.map, key, update_fun)

      %SortedMap{sorted_map | map: map}
    else
      raise KeyError, "key #{inspect(key)} not found in: #{inspect(sorted_map)}"
    end
  end

  @doc """
  Checks if the `map` contains `key`.

      iex> SortedMap.has_key?(SortedMap.new(a: 1, b: 2), :b)
      true

      iex> SortedMap.has_key?(SortedMap.new(a: 1, b: 2), :c)
      false
  """
  def has_key?(sorted_map, key) when is_map_key(sorted_map.map, key), do: true
  def has_key?(_, _), do: false

  @doc """
  Merges two maps into one, resolving conflicts through the given function. Same as `Map.merge/3` or `Keyword.merge/3`.

      iex> SortedMap.merge(SortedMap.new(a: 1, b: 2), SortedMap.new(c: 3))
      SortedMap.new(a: 1, b: 2, c: 3)

      iex> SortedMap.merge(SortedMap.new(a: 1, b: 2), SortedMap.new(c: 3, b: 4))
      SortedMap.new(a: 1, b: 4, c: 3)

      iex> SortedMap.merge(SortedMap.new(a: 1, b: 2), SortedMap.new(c: 3, b: 4), fn _, a, b -> a + b end)
      SortedMap.new(a: 1, b: 6, c: 3)

  """
  def merge(a, b, merge_fun \\ fn _key, _v1, v2 -> v2 end) do
    Enum.reduce(b, a, fn {key, value}, acc ->
      update(acc, key, value, &merge_fun.(key, &1, value))
    end)
  end

  @doc """
  Deletes the entry in map for a specific key.

  If the key does not exist, returns map unchanged.

  Same as `Map.delete/2` or `Keyword.delete/2`.

  ## Examples

      iex> SortedMap.delete(SortedMap.new(a: 1, b: 2), :a)
      SortedMap.new(b: 2)

      iex> SortedMap.delete(SortedMap.new(b: 2), :a)
      SortedMap.new(b: 2)

  """
  def delete(sorted_map, key) do
    if has_key?(sorted_map, key),
      do: %SortedMap{
        sorted_map
        | map: Map.delete(sorted_map.map, key),
          positions: List.delete(sorted_map.positions, key)
      },
      else: sorted_map
  end

  @doc """
  Removes the value associated with key in map and returns the value and the
  updated map.

  If key is present in map, it returns {value, updated_map} where value is the
  value of the key and updated_map is the result of removing key from map. If key
  is not present in map, {default, map} is returned.

  ## Examples

      iex> SortedMap.pop(SortedMap.new(a: 1), :a)
      {1, SortedMap.new([])}

      iex> SortedMap.pop(SortedMap.new(a: 1), :b)
      {nil, SortedMap.new(a: 1)}

      iex> SortedMap.pop(SortedMap.new(a: 1), :b, 3)
      {3, SortedMap.new(a: 1)}
  """
  def pop(sorted_map, key, default) do
    if has_key?(sorted_map, key),
      do: pop(sorted_map, key),
      else: {default, sorted_map}
  end

  @impl Access
  def fetch(%SortedMap{} = data, key), do: Access.fetch(data.map, key)

  @impl Access
  def get_and_update(%SortedMap{} = data, key, function) do
    case Access.get_and_update(data.map, key, function) do
      :pop ->
        pop(data, key)

      {value, map} ->
        positions =
          if key in data.positions do
            data.positions
          else
            data.positions ++ [key]
          end

        {value, %SortedMap{data | map: map, positions: positions}}
    end
  end

  @impl Access
  def pop(%SortedMap{} = data, key) do
    {value, new_map} = Map.pop(data.map, key)
    new_positions = List.delete(data.positions, key)
    {value, %SortedMap{data | map: new_map, positions: new_positions}}
  end

  defimpl Enumerable do
    def count(data), do: {:ok, Enum.count(data.map)}
    def member?(data, element), do: {:ok, Enum.member?(data.map, element)}

    def reduce(_list, {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(data, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(data, &1, fun)}
    def reduce(%{positions: []}, {:cont, acc}, _fun), do: {:done, acc}

    def reduce(%{positions: [head | tail]} = data, {:cont, acc}, fun) do
      reduce(%{data | positions: tail}, fun.({head, data[head]}, acc), fun)
    end

    def slice(data) do
      {:ok, Enum.count(data.map),
       fn start, length, step ->
         data.position
         |> Enum.slice(start..(start + length)//step)
         |> Enum.map(&data[&1])
       end}
    end
  end

  defimpl Collectable do
    def into(data) do
      fun = fn
        {acc, new_positions}, {:cont, {key, value}} ->
          acc = update_in(acc.map, &Map.put(&1, key, value))

          {acc, [key | new_positions]}

        {acc, new_positions}, :done ->
          update_in(acc.positions, fn positions ->
            Enum.uniq(positions ++ Enum.reverse(new_positions))
          end)

        _map_acc, :halt ->
          :ok
      end

      {{data, []}, fun}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(sorted_map, opts) do
      concat(["SortedMap.new(", Inspect.List.inspect(Enum.to_list(sorted_map), opts), ")"])
    end
  end
end
