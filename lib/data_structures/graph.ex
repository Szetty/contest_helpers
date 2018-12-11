defmodule Graph do

  defstruct value: nil

  def new(), do: %Graph{value: :digraph.new()}

  def new(vertices, edges) do
    graph = Graph.new()
    vertices
    |> Enum.each(fn
      {vertex, label} -> vertex(graph, vertex, label)
      vertex -> vertex(graph, vertex)
    end)
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

  def topological_sort(%Graph{} = graph, fun \\ &Kernel.</2) do
    {next, remaining} =
      graph
      |> get_vertices
      |> Enum.map(fn
        v when is_tuple(v) -> elem(v, 0)
        v -> v
      end)
      |> Enum.split_with(fn v ->
      (graph |> in_edges(v) |> Enum.count) === 0
    end)
    next_nodes = Enum.reduce(next, Heap.new(fun), &(Heap.push(&2, &1)))
    topo_sort(graph, next_nodes, MapSet.new, remaining, [])
  end

  def critical_path(%Graph{} = graph) do
    order = topological_sort(graph)
    [first | rest] = order
    {_, duration} = get_vertex(graph, first)
    es = %{} |> Map.put(first, duration)
    es = Enum.reduce(rest, es, fn node, acc ->
      {_, duration} = get_vertex(graph, node)
      time =
        in_neighbours(graph, node)
        |> Enum.map(&Map.get(acc, &1))
        |> Enum.max
      Map.put(acc, node, time + duration)
    end)

    [last | rest] = Enum.reverse(order)
    {_, duration} = get_vertex(graph, last)
    ls = %{} |> Map.put(last, Map.get(es, last) - duration)
    ls = Enum.reduce(rest, ls, fn node, acc ->
      {_, duration} = get_vertex(graph, node)
      time =
        out_neighbours(graph, node)
        |> Enum.map(&Map.get(acc, &1))
        |> Enum.min
      Map.put(acc, node, time - duration)
    end)
    Enum.filter(order, fn node ->
      {_, duration} = get_vertex(graph, node)
      Map.get(es, node) === Map.get(ls, node) + duration
    end)
  end

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

  defp topo_sort(graph, next_nodes, visited, vertices_remaining, list) do
    if Heap.size(next_nodes) === 0 do
      list
    else
      {next_nodes, node} = Heap.pop(next_nodes)
      list = list ++ [node]
      visited = out_edges(graph, node) |> MapSet.new |> MapSet.union(visited)
      {next, remaining} =
        Enum.split_with(vertices_remaining, fn v ->
          in_edges(graph, v) |> MapSet.new |> MapSet.subset?(visited)
        end)
      next_nodes = Enum.reduce(next, next_nodes, &(Heap.push(&2, &1)))
      topo_sort(graph, next_nodes, visited, remaining, list)
    end
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
