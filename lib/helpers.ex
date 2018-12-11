defmodule Helpers do
  import :math
  import Array

  def p(any, limit \\ 100), do: IO.puts(inspect(any, limit: limit))
  def identity, do: fn x -> x end
  def exit(), do: System.halt(0)
  def range2d(r1, r2), do: (for x <- r1, do: for y <- r2, do: {x, y}) |> List.flatten

  def len(container) do
    case Enumerable.impl_for(container) do
      nil ->
        case container do
          %{__struct__: module} -> :erlang.apply(module, :size, [container])
          _ -> raise "len not implemented for #{inspect(container)}"
        end
      _ -> Enum.count(container)
    end
  end

  def empty?(container) do
    case Enumerable.impl_for(container) do
      nil ->
        case container do
          %{__struct__: module} -> :erlang.apply(module, :is_empty?, [container])
          _ -> raise "len not implemented for #{inspect(container)}"
        end
      _ -> Enum.empty?(container)
    end
  end

  def mean(enumerable, fun \\ identity()), do: enumerable |> Enum.map(fun) |> Enum.sum |> Kernel./(Enum.count(enumerable))
  def variance(enumerable, fun \\ identity()) do
    enumerable = enumerable |> Enum.map(fun)
    mean = enumerable |> internal_mean
    enumerable |> Enum.map(fn x -> pow(x - mean, 2) end) |> internal_mean
  end
  def std_dev(enumerable, fun \\ identity()), do: enumerable |> variance(fun) |> sqrt()

  def loop(acc, func) do
    try do
      func.(acc)
    catch
      x -> x
    else
      acc -> loop(acc, func)
    end
  end

  def fix(f) do
    (fn z ->
      z.(z)
    end).(fn x ->
      f.(fn y -> (x.(x)).(y) end)
    end)
  end

  def to_fn(to) when is_atom(to) do
    case to do
      :i -> &String.to_integer/1
      :f -> &parse_float/1
      nil -> identity()
    end
  end

  def levenhstein(string1, string2) do
    G.set(:distances, %{})
    distance = do_levenhstein(string1 |> String.codepoints, string2 |> String.codepoints)
    G.stop()
    distance
  end

  def top(collection, k \\ 1, fun \\ &Kernel.</2) when is_function(fun, 2) do
    collection
    |> Enum.into([])
    |> new()
    |> quick_select(0, len(collection) - 1, k, fun)
    |> Enum.slice(0..(k - 1))
    |> Enum.sort(fun)
  end

  def to_i(any) do
    cond do
      any === true -> 1
      any === false -> 0
      is_binary(any) -> String.to_integer(any)
      is_atom(any) -> any |> Atom.to_string |> String.to_integer
      is_float(any) -> trunc(any)
      is_list(any) -> List.to_integer(any)
      is_integer(any) -> any
    end
  end

  def to_f(any) do
    cond do
      any === true -> 1.0
      any === false -> 0.0
      is_binary(any) -> parse_float(any)
      is_atom(any) -> any |> Atom.to_string |> parse_float
      is_float(any) -> any
      is_integer(any) -> any / 1
    end
  end

  # Internal

  defp internal_mean(enumerable), do: enumerable |> Enum.sum |> Kernel./(Enum.count(enumerable))

  defp parse_float(x) do
    {f, ""} = Float.parse(x)
    f
  end

  defp do_levenhstein([], s), do: len(s)
  defp do_levenhstein(s, []), do: len(s)
  defp do_levenhstein([c1 | s1] = str1, [c2 | s2] = str2) do
    case G.get(:distances)[{str1, str2}] do
      nil ->
        cost = if c1 === c2, do: 0, else: 1
        distance = Enum.min(
          [
            do_levenhstein(s1, str2) + 1,
            do_levenhstein(str1, s2) + 1,
            do_levenhstein(s1, s2) + cost
          ]
        )
        G.get_and_update(:distances, fn %{} = map ->
          Map.put(map, {str1, str2}, distance)
        end)
        distance
      value -> value
    end
  end

  defp quick_select(array, left, left, _k, _fun), do: array
  defp quick_select(array, left, right, k, fun) do
    pivot_index = :rand.uniform(right - left + 1) + left - 1
    {array, pivot_index} = partition(array, left, right, pivot_index, fun)
    cond do
      k === pivot_index -> array
      k < pivot_index -> quick_select(array, left, pivot_index - 1, k, fun)
      true -> quick_select(array, pivot_index + 1, right, k, fun)
    end
  end

  defp partition(array, left, right, pivot_index, fun) do
    pivot = array[pivot_index]
    array = Array.swap(array, pivot_index, right)
    {array, idx} =
      Enum.reduce(left..(right - 1), {array, left}, fn i, {array, idx} = acc ->
        if fun.(array[i], pivot) do
          {array |> Array.swap(i, idx), idx + 1}
        else
          acc
        end
      end)
    {array |> Array.swap(right, idx), idx}
  end
end
