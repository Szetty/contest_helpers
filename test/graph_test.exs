defmodule GraphTest do
  use ExUnit.Case
  import TestHelpers
  alias Graph, as: Gr

  test "acyclic graph" do
    graph =
      Gr.new()
      |> Gr.vertex(1, "a")
      |> Gr.vertex(2, 5)
      |> Gr.vertex(3, :a)
      |> Gr.vertex(4, [1,2])
      |> Gr.edge(1, {1, 2}, 3)
      |> Gr.edge(2, {1, 3}, 2)
      |> Gr.edge(3, {2, 4}, 1)
      |> Gr.edge(4, {3, 4}, 3)

    assert Gr.vertices_no(graph) === 4
    assert Gr.edges_no(graph) === 4

    assert Gr.get_vertex(graph, 1) === {1, "a"}
    assert Gr.get_vertex(graph, 2) === {2, 5}
    assert Gr.get_vertex(graph, 3) === {3, :a}
    assert Gr.get_vertex(graph, 4) === {4, [1,2]}
    assert Gr.get_vertex(graph, 0) === false
    assert Gr.get_vertex(graph, 5) === false
    assert Gr.get_vertex(graph, "a") === false

    assert Gr.get_edge(graph, 1) === {1, 1, 2, 3}
    assert Gr.get_edge(graph, 2) === {2, 1, 3, 2}
    assert Gr.get_edge(graph, 3) === {3, 2, 4, 1}
    assert Gr.get_edge(graph, 4) === {4, 3, 4, 3}
    assert Gr.get_edge(graph, 0) === false
    assert Gr.get_edge(graph, 5) === false

    assert Gr.edge?(graph, 1, 1) === false
    assert Gr.edge?(graph, 1, 2) === true
    assert Gr.edge?(graph, 1, 3) === true
    assert Gr.edge?(graph, 1, 4) === false
    assert Gr.edge?(graph, 2, 1) === false
    assert Gr.edge?(graph, 2, 2) === false
    assert Gr.edge?(graph, 2, 3) === false
    assert Gr.edge?(graph, 2, 4) === true
    assert Gr.edge?(graph, 3, 1) === false
    assert Gr.edge?(graph, 3, 2) === false
    assert Gr.edge?(graph, 3, 3) === false
    assert Gr.edge?(graph, 3, 4) === true
    assert Gr.edge?(graph, 4, 1) === false
    assert Gr.edge?(graph, 4, 2) === false
    assert Gr.edge?(graph, 4, 3) === false
    assert Gr.edge?(graph, 4, 4) === false

    assert Gr.in_degree(graph, 1) === 0
    assert Gr.in_degree(graph, 2) === 1
    assert Gr.in_degree(graph, 3) === 1
    assert Gr.in_degree(graph, 4) === 2

    assert Gr.out_degree(graph, 1) === 2
    assert Gr.out_degree(graph, 2) === 1
    assert Gr.out_degree(graph, 3) === 1
    assert Gr.out_degree(graph, 4) === 0

    assert Gr.in_edges(graph, 1) === []
    assert Gr.in_edges(graph, 2) === [1]
    assert Gr.in_edges(graph, 3) === [2]
    assert Gr.in_edges(graph, 4) === [3, 4]

    assert Gr.out_edges(graph, 1) === [1, 2]
    assert Gr.out_edges(graph, 2) === [3]
    assert Gr.out_edges(graph, 3) === [4]
    assert Gr.out_edges(graph, 4) === []

    assert Gr.in_neighbours(graph, 1) === []
    assert Gr.in_neighbours(graph, 2) === [1]
    assert Gr.in_neighbours(graph, 3) === [1]
    assert Gr.in_neighbours(graph, 4) === [3, 2]

    assert Gr.out_neighbours(graph, 1) === [3, 2]
    assert Gr.out_neighbours(graph, 2) === [4]
    assert Gr.out_neighbours(graph, 3) === [4]
    assert Gr.out_neighbours(graph, 4) === []

    assert Gr.topological_sort(graph) === [1, 2, 3, 4]

    graph = Gr.delete_vertex(graph, 4)

    assert Gr.vertices_no(graph) === 3
    assert Gr.edges_no(graph) === 2
    assert Gr.get_vertex(graph, 4) === false
    assert Gr.get_edge(graph, 3) === false
    assert Gr.get_edge(graph, 4) === false

    graph = Gr.delete_edge(graph, 1)

    assert Gr.vertices_no(graph) === 3
    assert Gr.edges_no(graph) === 1
    assert Gr.get_edge(graph, 1) === false
    assert Gr.get_edge(graph, 2) === {2, 1, 3, 2}
    assert_error "There is already an edge from 1 and to 3", do: Gr.edge(graph, 5, {1, 3}, nil)
  end

  test "cyclic graph" do
    graph =
      Gr.new()
      |> Gr.vertex(1)
      |> Gr.vertex(2)
      |> Gr.edge(1, {1, 1})

    assert Gr.vertices_no(graph) === 2
    assert Gr.edges_no(graph) === 1

    assert Gr.get_vertex(graph, 1) === {1, nil}
    assert Gr.get_vertex(graph, 2) === {2, nil}

    assert Gr.get_edge(graph, 1) === {1, 1, 1, nil}

    assert Gr.edge?(graph, 1, 1) === true
    assert Gr.edge?(graph, 1, 2) === false
    assert Gr.edge?(graph, 2, 1) === false
    assert Gr.edge?(graph, 2, 2) === false

    assert Gr.in_degree(graph, 1) === 1
    assert Gr.in_degree(graph, 2) === 0

    assert Gr.out_degree(graph, 1) === 1
    assert Gr.out_degree(graph, 2) === 0

    assert Gr.in_edges(graph, 1) === [1]
    assert Gr.in_edges(graph, 2) === []

    assert Gr.out_edges(graph, 1) === [1]
    assert Gr.out_edges(graph, 2) === []

    assert Gr.in_neighbours(graph, 1) === [1]
    assert Gr.in_neighbours(graph, 2) === []

    assert Gr.out_neighbours(graph, 1) === [1]
    assert Gr.out_neighbours(graph, 2) === []

    graph = Gr.vertex(graph, 2, "test")
    assert Gr.get_vertex(graph, 2) === {2, "test"}
    graph = Gr.edge(graph, 1, {1, 1}, "test1")
    assert Gr.get_edge(graph, 1) === {1, 1, 1, "test1"}
  end

  test "graph creation from lists" do
    graph = Gr.new(["a", "b", "c"], [{{"a", "b"}, :A}, {{"b", "c"}, :C}])

    assert Gr.vertices_no(graph) === 3
    assert Gr.edges_no(graph) === 2

    assert Gr.get_vertex(graph, "a") === {"a", nil}
    assert Gr.get_vertex(graph, "b") === {"b", nil}
    assert Gr.get_vertex(graph, "c") === {"c", nil}

    assert Gr.get_edge(graph, 1) === {1, "a", "b", :A}
    assert Gr.get_edge(graph, 2) === {2, "b", "c", :C}

    assert Gr.edge?(graph, "a", "a") === false
    assert Gr.edge?(graph, "a", "b") === true
    assert Gr.edge?(graph, "a", "c") === false
    assert Gr.edge?(graph, "b", "a") === false
    assert Gr.edge?(graph, "b", "b") === false
    assert Gr.edge?(graph, "b", "c") === true
    assert Gr.edge?(graph, "c", "a") === false
    assert Gr.edge?(graph, "c", "b") === false
    assert Gr.edge?(graph, "c", "c") === false

    assert Gr.in_degree(graph, "a") === 0
    assert Gr.in_degree(graph, "b") === 1
    assert Gr.in_degree(graph, "c") === 1

    assert Gr.out_degree(graph, "a") === 1
    assert Gr.out_degree(graph, "b") === 1
    assert Gr.out_degree(graph, "c") === 0

    assert Gr.in_edges(graph, "a") === []
    assert Gr.in_edges(graph, "b") === [1]
    assert Gr.in_edges(graph, "c") === [2]

    assert Gr.out_edges(graph, "a") === [1]
    assert Gr.out_edges(graph, "b") === [2]
    assert Gr.out_edges(graph, "c") === []

    assert Gr.in_neighbours(graph, "a") === []
    assert Gr.in_neighbours(graph, "b") === ["a"]
    assert Gr.in_neighbours(graph, "c") === ["b"]

    assert Gr.out_neighbours(graph, "a") === ["b"]
    assert Gr.out_neighbours(graph, "b") === ["c"]
    assert Gr.out_neighbours(graph, "c") === []

    assert Gr.topological_sort(graph) === ["a", "b", "c"]
  end

  test "floyd-warshall" do
    graph = Gr.new(
      [1, 2, 3, 4],
      [
        {{1, 3}, -2},
        {{3, 4}, 2},
        {{4, 2}, -1},
        {{2, 1}, 4},
        {{2, 3}, 3}
      ]
    )
    distances = Gr.floyd_warshall(graph)

    assert distances[{1, 1}] === 0
    assert distances[{1, 2}] === -1
    assert distances[{1, 3}] === -2
    assert distances[{1, 4}] === 0
    assert distances[{2, 1}] === 4
    assert distances[{2, 2}] === 0
    assert distances[{2, 3}] === 2
    assert distances[{2, 4}] === 4
    assert distances[{3, 1}] === 5
    assert distances[{3, 2}] === 1
    assert distances[{3, 3}] === 0
    assert distances[{3, 4}] === 2
    assert distances[{4, 1}] === 3
    assert distances[{4, 2}] === -1
    assert distances[{4, 3}] === 1
    assert distances[{4, 4}] === 0
  end

  test "dfs and bfs" do
    graph = Gr.new(
      [:A, :B, :C, :D, :E, :F, :G],
      [
        {:A, :B}, {:B, :D}, {:B, :F}, {:F, :E}, {:A, :C}, {:C, :G}, {:A, :E}, {:E, :F}
      ]
    )

    assert Gr.dfs(graph, :A) === [:A, :B, :D, :F, :E, :C, :G]
    assert Gr.bfs(graph, :A) === [:A, :E, :C, :B, :F, :G, :D]
  end

  test "topological sort with compare" do
    graph = Gr.new(
      [:a, :b, :c, :d, :e, :f],
      [{:c, :a}, {:c, :f}, {:a, :b}, {:a, :d}, {:b, :e}, {:d, :e}, {:f, :e}]
    )

    assert Gr.topological_sort(graph) === [:c, :a, :b, :d, :f, :e]
    assert Gr.topological_sort(graph, fn a, b -> a > b end) === [:c, :f, :a, :d, :b, :e]
  end

end
