defmodule Helpers do
  import :math

  def identity, do: fn x -> x end

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

  def to_fn(to) when is_atom(to) do
    case to do
      :i -> &String.to_integer/1
      :f -> &parse_float/1
      nil -> identity()
    end
  end

  defp internal_mean(enumerable), do: enumerable |> Enum.sum |> Kernel./(Enum.count(enumerable))

  defp parse_float(x) do
    {f, ""} = Float.parse(x)
    f
  end
end

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

defmodule Array do

  @behaviour Access

  defstruct value: :array.new([{:default, nil}])

  def new() do
    %__MODULE__{}
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

  @impl Access
  def fetch(%__MODULE__{value: value}, key), do: internal_get(value, key)

  @impl Access
  def get(struct, key, default \\ nil), do: fetch(struct, key) || default

  @impl Access
  def get_and_update(%__MODULE__{value: value}, key, fun) when is_function(fun, 1) do
    {:ok, current} = internal_get(value, key)

    case fun.(current) do
      {get, update} ->
        {get, %__MODULE__{value: :array.set(key, update, value)}}

      :pop ->
        {current, %__MODULE__{value: :array.reset(key, value) |> :array.resize()}}

      other ->
        raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
    end
  end

  @impl Access
  def pop(%__MODULE__{value: value}, key, default \\ nil) do
    {:ok, val} =  internal_get(value, key) || default
    array =
      :array.reset(key, value)
      |> :array.resize
    {val, %__MODULE__{value: array}}
  end

  defp internal_get(array, key) do
    {:ok, :array.get(key, array)}
  end

  defmacro a <~ b do
    quote do
      put_in unquote(a), unquote(b)
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

defmodule Stack do
  defstruct elements: []

  def new, do: %Stack{}

  def push(%Stack{elements: elements} = stack, element) do
    %{stack | elements: [element | elements]}
  end

  def pop(%Stack{elements: []}), do: raise("Stack is empty!")
  def pop(%Stack{elements: [top | rest]} = stack) do
    {top, %{stack | elements: rest}}
  end

  def peek(%Stack{elements: []}), do: nil
  def peek(%Stack{elements: [top | _]}), do: top

  def apply_on_top(%Stack{elements: []}), do: raise("Stack is empty!")
  def apply_on_top(%Stack{elements: [top | rest]} = stack, fun) do
    %{stack | elements: [fun.(top) | rest]}
  end

  def is_empty?(%Stack{elements: elements}), do: elements === []
end

defmodule Queue do
  defstruct elements: :array.new([{:default, nil}]), next: 0, resize_limit: 100_000_000

  def new(), do: %Queue{}

  def enqueue(%Queue{elements: array} = queue, element) do
    %{queue | elements: :array.set(:array.size(array), element, array)}
  end

  def dequeue(%Queue{elements: array, next: next, resize_limit: resize_limit} = queue) do
    if is_empty?(queue) do
      raise "Queue is empty!"
    else
      value = :array.get(next, array)
      {array, next} =
        :array.reset(next, array)
        |> resize_if_needed(next + 1, resize_limit)
      {value, %{queue | elements: array, next: next}}
    end
  end

  def peek(%Queue{elements: array, next: next} = queue) do
    if is_empty?(queue) do
     nil
    else
      :array.get(next, array)
    end
  end

  defp resize_if_needed(array, next, resize_limit) do
    size = :array.size(array)
    if size > resize_limit && next > size / 4 do
      new_array =
        next..(size - 1)
        |> Enum.reduce(:array.new([{:default, nil}]), fn index, acc ->
        :array.set(index - next, :array.get(index, array), acc)
      end)
      {new_array, 0}
    else
      {array, next}
    end
  end

  def is_empty?(%Queue{elements: array, next: next}), do: next === :array.size(array)
end

defmodule Heap do
  defstruct elems: %Array{}, comp: &Kernel.</2

  def new(comp \\ &Kernel.</2) do
    %Heap{comp: comp}
  end

  def peek(heap) do
    heap.elems[0]
  end

  def push(heap, elem) do
    index = size(heap)
    heap
    |> update(index, elem)
    |> heapify_up(index)
  end

  def pop(heap) do
    elem = heap.elems[0]
    heap =
      heap
      |> update(0, heap.elems[last_index(heap)])
      |> delete(last_index(heap))
      |> heapify_down(0)
    {heap, elem}
  end

  def size(heap), do: Enum.count(heap.elems)

  def heapify(enumerable, comp \\ &Kernel.</2), do: Enum.reduce(enumerable, Heap.new(comp), &Heap.push(&2, &1))

  defp heapify_up(heap, index) do
    parent_index = parent(index)
    elem = heap.elems[index]
    parent = heap.elems[parent_index]
    cond do
      root?(index) || !heap.comp.(elem, parent) -> heap
      true ->
        heap
        |> update(index, parent)
        |> update(parent_index, elem)
        |> heapify_up(parent_index)
    end
  end

  defp heapify_down(heap, index) do
    current = heap.elems[index]
    {child_index, child} = next_child(heap, index)
    cond do
      leaf?(heap, index) || heap.comp.(current, child) -> heap
      true ->
        heap
        |> update(index, child)
        |> update(child_index, current)
        |> heapify_down(child_index)
    end
  end

  defp update(%Heap{elems: elems} = heap, index, elem), do: %{heap | elems: put_in(elems[index], elem)}
  defp delete(%Heap{elems: elems} = heap, index), do: %{heap | elems: (pop_in(elems[index]) |> elem(1))}

  defp next_child(heap, index) do
    left_index = left_child(index)
    right_index = right_child(index)
    left = heap.elems[left_index]
    right = heap.elems[right_index]
    cond do
      left === nil -> {nil, nil}
      right === nil -> {left_index, left}
      heap.comp.(left, right) -> {left_index, left}
      true -> {right_index, right}
    end
  end

  defp parent(index), do: (index / 2) |> trunc
  defp left_child(index), do: 2 * index + 1
  defp right_child(index), do: 2 * index + 2

  defp leaf?(heap, index), do: (index * 2) >= last_index(heap)
  defp root?(index), do: index === 0

  defp last_index(heap), do: size(heap) - 1
end

defmodule Trie do
  defstruct value: %{}, key_fn: nil
  @meta_keys [:size, :element]

  def new(), do: %Trie{}

  def insert(%Trie{value: value} = trie, element) do
    key = apply_key_fn(trie, element)
    map = do_insert(value, key |> String.codepoints, element)
    %{trie | value: map}
  end

  def count(%Trie{value: value}, prefix) do
    do_count(value, String.codepoints(prefix))
  end

  def search(%Trie{value: value}, prefix) do
    do_find(value, String.codepoints(prefix))
  end

  defp apply_key_fn(%Trie{key_fn: nil}, element), do: Helpers.identity.(element)
  defp apply_key_fn(%Trie{key_fn: key_fn}, element) when is_function(key_fn, 1), do: key_fn.(element)

  defp do_insert(%{} = map, [], element), do: Map.put(map, :element, element)
  defp do_insert(%{} = map, [char | rest], element) do
    size = Map.get(map, :size, 0)
    submap =
      case map[char] do
        nil ->
          rest
          |> Enum.reverse
          |> Enum.reduce(
            %{size: 1, element: element}, fn x, acc ->
            Map.put(%{size: 1}, x, acc)
          end)

        %{} = sub_map ->
          do_insert(sub_map, rest, element)
      end
    map
    |> Map.put(char, submap)
    |> Map.put(:size, size + 1)
  end

  defp do_count(%{size: size}, []), do: size
  defp do_count(%{} = map, [char | rest]) do
    case map[char] do
      nil -> 0
      %{} = sub_map -> do_count(sub_map, rest)
    end
  end

  defp do_find(%{} = map, []), do: do_build_list(map)
  defp do_find(%{} = map, [char | rest]) do
    case map[char] do
      nil -> []
      %{} = sub_map -> do_find(sub_map, rest)
    end
  end

  defp do_build_list(%{} = map) do
    case Map.get(map, :element, nil) do
      nil -> []
      element -> [element]
    end
    |> Kernel.++(
      map
      |> Enum.filter(fn {key, _} -> !Enum.member?(@meta_keys, key) end)
      |> Enum.map(fn {_, sub_map} -> do_build_list(sub_map) end)
      |> List.flatten
    )
  end
end

defmodule BinTree do
  defstruct elements: []

  def new(elements) do
    if binary?(elements) do
      %BinTree{elements: elements}
    else
      raise "Not a binary tree"
    end
  end

  def preorder(%BinTree{elements: elements}), do: do_preorder(elements)
  def inorder(%BinTree{elements: elements}), do: do_inorder(elements)
  def postorder(%BinTree{elements: elements}), do: do_postorder(elements)
  def height(%BinTree{elements: elements}), do: calculate_height(elements, 0)

  defp binary?([root, left, right]) when not is_list(root), do: binary?(left) && binary?(right)
  defp binary?([root, left]) when not is_list(root), do: binary?(left)
  defp binary?([root]) when not is_list(root), do: true
  defp binary?([]), do: true
  defp binary?(element) when is_list(element), do: false
  defp binary?(_), do: true

  defp do_preorder([root, left, right]) when not is_list(root), do: [root | do_preorder(left)] ++ do_preorder(right)
  defp do_preorder([root, left]) when not is_list(root), do: [root | do_preorder(left)]
  defp do_preorder([root]) when not is_list(root), do: [root]
  defp do_preorder([]), do: []
  defp do_preorder(root) when not is_list(root), do: [root]

  defp do_inorder([root, left, right]) when not is_list(root), do: do_inorder(left) ++ [root] ++ do_inorder(right)
  defp do_inorder([root, left]) when not is_list(root), do: [root | do_inorder(left)]
  defp do_inorder([root]) when not is_list(root), do: [root]
  defp do_inorder([]), do: []
  defp do_inorder(root) when not is_list(root), do: [root]

  defp do_postorder([root, left, right]) when not is_list(root), do: do_postorder(left) ++ do_postorder(right) ++ [root]
  defp do_postorder([root, left]) when not is_list(root), do: [root | do_postorder(left)]
  defp do_postorder([root]) when not is_list(root), do: [root]
  defp do_postorder([]), do: []
  defp do_postorder(root) when not is_list(root), do: [root]

  defp calculate_height([root, left, right], current_height) when not is_list(root), do: max(calculate_height(left, current_height + 1), calculate_height(right, current_height + 1))
  defp calculate_height([root, left], current_height) when not is_list(root), do: calculate_height(left, current_height + 1)
  defp calculate_height([root], current_height) when not is_list(root), do: current_height
  defp calculate_height([], current_height), do: current_height - 1
  defp calculate_height(root, current_height) when not is_list(root), do: current_height
end

defmodule Tree do

  defstruct elements: []

  def new(), do: %Tree{}
  def new(elements), do: %Tree{elements: elements}

  def sigil_t(string, []), do: parse(string)
  def sigil_t(string, [?s]), do: parse(string, Helpers.identity())
  def sigil_t(string, [?f]), do: parse(string, fn x -> x |> Float.parse |> elem(0) end)
  def sigil_t(string, [?b]), do: parse_binary(string)
  def sigil_t(string, [?b, ?s]), do: parse_binary(string, Helpers.identity())
  def sigil_t(string, [?b, ?f]), do: parse_binary(string, fn x -> x |> Float.parse |> elem(0) end)

  defp parse(string, mapper \\ &String.to_integer/1) do
    string
    |> String.codepoints
    |> parse("", Stack.new |> Stack.push([]), mapper)
    |> new
  end

  defp parse_binary(string, mapper \\ &String.to_integer/1) do
    string
    |> String.codepoints
    |> parse("", Stack.new |> Stack.push([]), mapper)
    |> BinTree.new
  end

  defp parse([], "", %Stack{elements: [tree]}, _mapper), do: tree |> Enum.reverse
  defp parse([], current_elem, %Stack{elements: [tree]}, mapper) do
    [current_elem |> mapper.() | tree] |> Enum.reverse
  end
  defp parse([char | rest], current_elem, stack, mapper) do
    {current_elem, stack} =
      case char do
        " " ->
          stack = put_elem_in_top_list_if_not_empty(stack, current_elem, mapper)
          {"", stack}
        "(" ->
          {"", Stack.push(stack, [])}
        ")" ->
          stack = put_elem_in_top_list_if_not_empty(stack, current_elem, mapper)
          {inner_list, stack} = Stack.pop(stack)
          inner_list = inner_list |> Enum.reverse
          stack = Stack.apply_on_top(stack, fn top_list -> [inner_list | top_list] end)
          {"", stack}
        char ->
          {current_elem <> char, stack}
    end
    parse(rest, current_elem, stack, mapper)
  end

  defp put_elem_in_top_list_if_not_empty(stack, current_elem, mapper) do
    if current_elem != "" do
      Stack.apply_on_top(stack, fn top_list -> [mapper.(current_elem) | top_list] end)
    else
      stack
    end
  end
end

defmodule Graph do

  defstruct value: nil

  def new(), do: %Graph{value: :digraph.new()}

  def new(vertices, edges) do
    graph = Graph.new()
    vertices
    |> Enum.each(fn vertex -> vertex(graph, vertex) end)
    edges
    |> Enum.with_index()
    |> Enum.each(fn
      {{{_from, _to} = vertex_pair, label}, id} -> edge(graph, id + 1, vertex_pair, label)
      {{_from, _to} = vertex_pair, id} -> edge(graph, id + 1, vertex_pair, nil)
    end)
    graph
  end

  # Adds or updates vertex
  def vertex(%Graph{value: value} = graph, id, label \\ nil) do
    :digraph.add_vertex(value, id, label)
    graph
  end

  #Adds or updates edge
  def edge(%Graph{value: value} = graph, id, {from, to}, label \\ nil) do
    if Graph.edge?(graph, from, to) && Graph.get_edge(graph, id) === false do
      raise "There is already an edge from #{from} and to #{to}"
    else
      :digraph.add_edge(value, id, from, to, label)
    end
    graph
  end

  def get_vertices(%Graph{value: value}), do: :digraph.vertices(value)
  def get_edges(%Graph{value: value}), do: :digraph.edges(value)

  def get_vertex(%Graph{value: value}, vertex_id), do: :digraph.vertex(value, vertex_id)
  def get_edge(%Graph{value: value}, edge_id), do: :digraph.edge(value, edge_id)

  def vertices_no(%Graph{value: value}), do: :digraph.no_vertices(value)
  def edges_no(%Graph{value: value}), do: :digraph.no_edges(value)

  def in_degree(%Graph{value: value}, vertex_id), do: :digraph.in_degree(value, vertex_id)
  def in_edges(%Graph{value: value}, vertex_id), do: :digraph.in_edges(value, vertex_id)
  def in_neighbours(%Graph{value: value}, vertex_id), do: :digraph.in_neighbours(value, vertex_id)

  def out_degree(%Graph{value: value}, vertex_id), do: :digraph.out_degree(value, vertex_id)
  def out_edges(%Graph{value: value}, vertex_id), do: :digraph.out_edges(value, vertex_id)
  def out_neighbours(%Graph{value: value}, vertex_id), do: :digraph.out_neighbours(value, vertex_id)

  def edge?(%Graph{value: value}, from, to), do: :digraph.get_path(value, from, to) === [from, to]

  def delete_vertex(%Graph{value: value} = graph, vertex_id) do
    :digraph.del_vertex(value, vertex_id)
    graph
  end

  def delete_edge(%Graph{value: value} = graph, edge_id) do
    :digraph.del_edge(value, edge_id)
    graph
  end

  def topological_sort(%Graph{value: value}), do: :digraph_utils.topsort(value)

  def dfs(%Graph{} = graph, vertex_id) do
    stack = Stack.new() |> Stack.push(vertex_id)
    G.set(:graph, graph)
    vertices = do_dfs(stack, [], MapSet.new) |> Enum.reverse
    G.stop()
    vertices
  end

  def bfs(%Graph{} = graph, vertex_id) do
    stack = Queue.new() |> Queue.enqueue(vertex_id)
    G.set(:graph, graph)
    vertices = do_bfs(stack, [], MapSet.new) |> Enum.reverse
    G.stop()
    vertices
  end

  def floyd_warshall(%Graph{} = graph) do
    dist = %{}
    edges = graph |> get_edges() |> Enum.map(fn edge ->
      {_edge, from, to, weight} = Graph.get_edge(graph, edge)
      {from, to, weight}
    end)
    vertices = graph |> get_vertices()
    dist =
      edges
      |> Enum.reduce(dist, fn {from, to, weight}, acc -> Map.put(acc, {from, to}, weight) end)
    dist =
      vertices
      |> Enum.reduce(dist, fn vertex, acc -> Map.put(acc, {vertex, vertex}, 0) end)
    Enum.reduce(vertices, dist, fn k, acc ->
      Enum.reduce(vertices, acc, fn i, acc ->
        Enum.reduce(vertices, acc, fn j, acc ->
          new_weight = if(acc[{i, k}] === nil || acc[{k, j}] === nil) do
              nil
            else
              acc[{i, k}] + acc[{k, j}]
            end
          if(acc[{i, j}] > new_weight) do
            Map.put(acc, {i, j}, new_weight)
          else
            acc
          end
        end)
      end)
    end)
  end

  defp do_dfs(%Stack{elements: []}, vertices, _discovered), do: vertices
  defp do_dfs(%Stack{} = stack, vertices, discovered) do
    import Stack
    {new_vertex, stack} = pop(stack)
    case MapSet.member?(discovered, new_vertex) do
      true -> do_dfs(stack, vertices, discovered)
      false ->
        stack =
          G.get(:graph)
          |> out_neighbours(new_vertex)
          |> Enum.reduce(stack, fn vertex, acc -> push(acc, vertex) end)
        do_dfs(stack, [new_vertex | vertices], MapSet.put(discovered, new_vertex))
    end
  end

  defp do_bfs(%Queue{} = queue, vertices, discovered) do
    import Queue
    if Helpers.empty?(queue) do
      vertices
    else
      {new_vertex, queue} = dequeue(queue)
      {queue, vertices, discovered} =
        case MapSet.member?(discovered, new_vertex) do
          true ->
            {queue, vertices, discovered}
          false ->
            queue =
              G.get(:graph)
              |> out_neighbours(new_vertex)
              |> Enum.reduce(queue, fn vertex, acc -> enqueue(acc, vertex) end)
            {queue, [new_vertex | vertices], MapSet.put(discovered, new_vertex)}
      end
      do_bfs(queue, vertices, discovered)
    end
  end
end

defmodule GeneralAlgorithms do

  def backtrack(data, accept_fn, reject_fn) do
    G.set(:accept, accept_fn)
    G.set(:reject, reject_fn)
    G.set(:data, data)
    solutions = do_backtrack([]) |> Enum.map(&Kernel.elem(&1, 0))
    G.stop()
    solutions
  end

  defp do_backtrack(solution) do
    continue_backtrack_fn = fn fun ->
      G.get(:data)
      |> fun.(fn element ->
        do_backtrack(solution ++ [element])
      end)
      |> List.flatten
    end
    cond do
      solution === [] ->
        continue_backtrack_fn.(&Parallel.map/2)
      G.get(:reject).(solution) ->
        []
      G.get(:accept).(solution) ->
        {solution}
      true ->
        continue_backtrack_fn.(&Enum.map/2)
    end
  end

end

defmodule Parallel do

  def map(collection, func, max_concurrency \\ 8) do
    collection
    |> Task.async_stream(func, max_concurrency: max_concurrency, timeout: :infinity)
    |> Enum.map(fn {:ok, result} -> result end)
  end

end

defmodule Reader do

  def from_file(filename, opts \\ []) do
    filename |> File.open! |> from_device(opts)
  end

  def from_device(device, opts \\ []) do
    device |> IO.read(:all) |> from_string(opts)
  end

  def from_string(string, opts \\ []) do
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
      |> Enum.map(fn line -> String.split(line, column_delimiter) |> to_fn.() end)
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

  def to_file(data, filename, opts \\ []) do
    data = data |> to_string(opts)
    File.write!(filename, data)
  end

  def to_string(data, opts \\ []) do
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
      import Enum, except: [count: 2, empty?: 1]
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
      alias GeneralAlgorithms, as: Algos
    end
  end
end
