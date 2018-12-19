defmodule G do
  @process_name :global_variables

  def start() do
    {:ok, pid} = Agent.start(fn -> %{} end)
    true = Process.register(pid, @process_name)
  end

  def stop() do
    if registered?() do
      Agent.stop(@process_name)
    end
  end

  def get(key) do
    if registered?() do
      Agent.get(@process_name, fn %{} = map -> Map.get(map, key) end)
    else
      nil
    end
  end

  def get_and_update(key, fun) do
    if registered?() do
      Agent.get_and_update(@process_name, fn %{} = map ->
        old_value = Map.get(map, key)
        new_value = fun.(old_value)
        {old_value, Map.put(map, key, new_value)}
      end)
    else
      nil
    end
  end

  def set(key, value) do
    if !registered?() do
      G.start()
    end
    Agent.update(@process_name, fn %{} = map -> Map.put(map, key, value) end)
  end

  def set_p(key, value) do
    if !registered?() do
      G.start
    end
    Agent.cast(@process_name, fn %{} = map -> Map.put(map, key, value) end)
  end

  defp registered?(), do: Enum.member?(Process.registered(), @process_name)
end

defmodule Parallel do

  def map(collection, func, max_concurrency \\ 8) do
    collection
    |> Task.async_stream(func, max_concurrency: max_concurrency, timeout: :infinity)
    |> Enum.map(fn {:ok, result} -> result end)
  end

end

defmodule Reader do

  def f(filename, opts \\ []) do
    filename |> File.open! |> device(opts)
  end

  def device(device, opts \\ []) do
    device |> IO.read(:all) |> string(opts)
  end

  def string(string, opts \\ []) do
    line_delimiter = Keyword.get(opts, :line, "\n")
    column_delimiter = Keyword.get(opts, :column, nil)
    to_fn = Keyword.get(opts, :to, nil) |> Helpers.to_fn
    lines =
      string
      |> String.trim(line_delimiter)
      |> String.split(line_delimiter)
      |> Enum.filter(fn x -> x !== "" end)
    if column_delimiter !== nil do
      lines
      |> Enum.map(fn line ->
        String.split(line, column_delimiter)
        |> Enum.filter(fn x -> x !== "" end)
        |> to_fn.()
      end)
    else
      lines
      |> Enum.map(to_fn)
    end
  end

  def reduce_big_file(filename, acc, fun, opts \\ []) do
    filename |> File.open! |> reduce_big_device(acc, fun, opts)
  end

  def reduce_big_device(device, acc, fun, opts \\ []) do
    column_delimiter = Keyword.get(opts, :column, ",")
    reduce(device, IO.read(device, :line), acc, fun, column_delimiter)
  end

  defp reduce(_device, :eof, acc, _fun, _column), do: acc
  defp reduce(device, line, acc, fun, column_delimiter) do
    acc = line
    |> String.trim()
    |> String.split(column_delimiter)
    |> fun.(acc)
    reduce(device, IO.read(device, :line), acc, fun, column_delimiter)
  end

end

defmodule Writer do

  def file(data, filename, opts \\ []) do
    data = data |> string(opts)
    File.write!(filename, data)
  end

  def string(data, opts \\ []) do
    line_joiner = Keyword.get(opts, :line, "\n")
    column_joiner = Keyword.get(opts, :column, ",")
    data
    |> Enum.map(&Enum.join(&1, column_joiner))
    |> Enum.join(line_joiner)
  end

end

defmodule DataStructures do
  @moduledoc """
  Examples of usages

  use DataStructures, which: [Array]

  data structures supported are: Array, Tree, BinTree, Heap, Stack, Queue, Graph, Trie

  for using global module, just use G.set and G.get
  """

  defmacro __using__(_opts) do
    quote do
      import Helpers
      import :math
      import Enum, except: [empty?: 1]
      import Array, only: :macros
      alias Array, as: A
      alias BinTree, as: BT
      import Tree, only: [sigil_t: 2]
      alias Tree, as: T
      alias Heap, as: H
      alias MapSet, as: S
      alias Stack, as: St
      alias Queue, as: Q
      alias Graph, as: Gr
      alias Algorithms.General, as: Algos
      alias Reader, as: In
      alias Writer, as: Out
      alias String, as: Str
      alias Keyword, as: KW
    end
  end
end
