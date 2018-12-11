defmodule Array do

  @behaviour Access

  defstruct value: :array.new([{:default, nil}])

  def new() do
    %Array{}
  end

  def new(list) when is_list(list) do
    Enum.with_index(list) |> Enum.reduce(new(), fn {item, index}, array ->
      item = if is_list(item) do
        item |> new
      else
        item
      end
      put_in array, [index], item
    end)
  end

  def new(size, default \\ nil) when is_integer(size) do
    %Array{value: :array.new([{:size, size}, {:fixed, true}, {:default, default}])}
  end

  def new2d(size_x, size_y, default \\ nil) when is_integer(size_x) and is_integer(size_y) do
    inner_array = %Array{value: :array.new([{:size, size_y}, {:fixed, true}, {:default, default}])}
    outer_array = :array.new([{:size, size_x}, {:fixed, true}, {:default, inner_array}])
    %Array{value: outer_array}
  end

  @impl Access
  def fetch(%Array{value: value}, key), do: {:ok, do_get(value, key)}

  @impl Access
  def get(struct, key, default \\ nil), do: fetch(struct, key) || default

  @impl Access
  def get_and_update(%Array{value: value}, key, fun) when is_function(fun, 1) do
    {do_get(value, key), %Array{value: do_update(value, key, fun) |> resize_if_not_fixed}}
  end

  @impl Access
  def pop(%Array{value: value}, key, default \\ nil) do
    val = do_get(value, key)
    {val || default, %Array{value: do_update(value, key, fn _ -> :pop end) |> resize_if_not_fixed}}
  end

  def swap(%Array{} = array, idx1, idx2) do
    array
    |> put_in([idx1], array[idx2])
    |> put_in([idx2], array[idx1])
  end

  def to_list(%Array{value: value}) do
    case value do
      {:array, _size, 0, _default, _elements} ->
        f = fn
          _idx, %Array{} = el, acc -> [to_list(el) | acc]
          _idx, el, acc -> [el | acc]
        end
        :array.foldr(f, [], value)
      {:array, size, _capacity, _default, elements} when is_tuple(elements) ->
        elements |> Tuple.to_list |> Enum.take(size) |> Enum.map(fn
          %Array{} = el -> to_list(el)
          el -> el
        end)
      {:array, _size, _capacity, _default, _elements} -> []
    end
  end

  defmacro a <~ b do
    quote do
      put_in unquote(a), unquote(b)
    end
  end

  defp do_get(array, key) do
    case key do
      {key1, key2} -> do_get2d(array, key1, key2)
      _left.._right -> Enum.map(key, &internal_get(array, &1))
      nr when is_integer(nr) -> internal_get(array, nr)
      _ -> raise "Invalid index #{key}"
    end
  end

  defp do_update(array, key, update_fun) do
    case key do
      {key1, key2} -> do_update2d(array, key1, key2, update_fun)
      _left.._right -> Enum.reduce(key, array, &do_update_or_remove(&2, &1, update_fun))
      nr when is_integer(nr) -> do_update_or_remove(array, nr, update_fun)
      _ -> raise "Invalid index #{key}"
    end
  end

  defp do_get2d(array, key1, key2) do
    case do_get(array, key1) do
      %Array{value: value} -> do_get(value, key2)
      list when is_list(list) ->
        Enum.map(list, fn %Array{value: value} -> do_get(value, key2) end)
        |> List.flatten
      _ -> raise "Invalid index #{key1}"
    end
  end

  defp do_update2d(array, key1, key2, update_fun) do
    case do_get(array, key1) do
      %Array{value: value} ->
        nested_array = do_update(value, key2, update_fun)
        internal_update(array, key1, nested_array)
      list when is_list(list) ->
        Enum.map(list, fn %Array{value: value} ->
          do_update(value, key2, update_fun)
        end)
        |> Enum.zip(key1)
        |> Enum.reduce(array, fn {value, key}, acc -> internal_update(acc, key, %Array{value: value}) end)
      _ -> raise "Invalid index #{key1}"
    end
  end

  defp internal_get(array, key) do
    try do
      :array.get(key, array)
    rescue
      ArgumentError -> raise "Index out of bounds, with index #{inspect(key)}"
    end
  end

  defp do_update_or_remove(array, key, update_fun) do
    case internal_get(array, key) |> update_fun.() do
      {_get, update} ->
        internal_update(array, key, update)

      :pop ->
        internal_remove(array, key)

      other ->
        raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
    end
  end

  defp internal_update(array, key, value) do
    try do
      :array.set(key, value, array)
    rescue
      ArgumentError -> raise "Index out of bounds, with index #{key}"
    end
  end

  defp internal_remove(array, key) do
    try do
      :array.reset(key, array)
    rescue
      ArgumentError -> raise "Index out of bounds, with index #{key}"
    end
  end

  defp resize_if_not_fixed(array) do
    if :array.is_fix(array) do
      array
    else
      :array.resize(array)
    end
  end

  defimpl Enumerable do
    def member?(_array, _value), do: {:error, __MODULE__}

    def count(%Array{value: value}), do: {:ok, :array.size(value)}
    def reduce(%Array{value: value} = array, acc, fun) do
      do_reduce(array, acc, fun, 0, :array.size(value))
    end
    def slice(%Array{value: value} = array), do: {:ok, :array.size(value), &do_slice(array, &1, &2)}

    defp do_reduce(_, {:halt, acc}, _, _, _) do
      {:halted, acc}
    end

    defp do_reduce(array, {:suspend, acc}, fun, current_index, max_index) do
      {:suspended, acc, &do_reduce(array, &1, fun, current_index, max_index)}
    end

    defp do_reduce(%Array{value: value} = array, {:cont, acc}, fun, current_index, max_index) when current_index < max_index do
      current_element = :array.get(current_index, value)
      do_reduce(array, fun.(current_element, acc), fun, current_index + 1, max_index)
    end

    defp do_reduce(_, {:cont, acc}, _, _, _) do
      {:done, acc}
    end

    defp do_slice(%Array{value: value}, current_index, 1), do: [:array.get(current_index, value)]

    defp do_slice(%Array{value: value} = array, current_index, remaining) do
      [:array.get(current_index, value) | do_slice(array, current_index + 1, remaining - 1)]
    end
  end
end
