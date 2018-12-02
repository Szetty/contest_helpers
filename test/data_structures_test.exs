defmodule DataStructuresTest do
  use ExUnit.Case
  use DataStructures

  test "levenhstein" do
    assert levenhstein("s", "s") === 0
    assert levenhstein("s", "k") === 1
    assert levenhstein("ss", "ss") === 0
    assert levenhstein("sk", "sj") === 1
    assert levenhstein("kitten", "sitten") === 1
    assert levenhstein("kitten", "sitting") === 3
  end

  test "array" do
    array = [1, 2, 3] |> A.new
    assert len(array) === 3
    assert array[0] === 1
    assert array[2] === 3
    assert array[5] === nil

    array = array[1] <~ 4
    assert array[1] === 4

    {3, array} = pop_in(array, [2])
    assert len(array) === 2
    assert array[2] === nil

    array = array[2] <~ 7
    assert array[2] === 7

    {7, array} = pop_in(array[2])
    assert len(array) === 2
    assert array[2] === nil
  end

  test "multi-dimensional array" do
    array = [
      [1, 2, [3, 3.5]],
      [4, 5, 6],
      [7, 8, 9]
    ] |> A.new
    assert array[0][0] === 1
    assert array[0][1] === 2
    assert array[0][2][0] === 3
    assert array[0][2][1] === 3.5
    assert array[1][0] === 4
    assert array[1][1] === 5
    assert array[1][2] === 6
    assert array[2][0] === 7
    assert array[2][1] === 8
    assert array[2][2] === 9
  end

  test "heap" do
    heap = H.new()
    assert H.peek(heap) === nil
    heap = H.push(heap, 10)
    assert len(heap) === 1
    assert H.peek(heap) === 10
    {heap, 10} = H.pop(heap)
    assert len(heap) === 0
    assert H.peek(heap) == nil
    heap = H.heapify([4, 1, 31, 67, 19])
    assert len(heap) === 5
    {heap, 1} = H.pop(heap)
    {heap, 4} = H.pop(heap)
    {heap, 19} = H.pop(heap)
    {heap, 31} = H.pop(heap)
    {heap, 67} = H.pop(heap)
    assert len(heap) === 0
    comp = fn x,y -> String.length(x) > String.length(y) end
    heap = H.heapify(["abcde", "a", "abc", "ab", "abcdef", "abcd", "abc"], comp)
    assert len(heap) === 7
    {heap, "abcdef"} = H.pop(heap)
    {heap, "abcde"} = H.pop(heap)
    {heap, "abcd"} = H.pop(heap)
    {heap, "abc"} = H.pop(heap)
    {heap, "abc"} = H.pop(heap)
    {heap, "ab"} = H.pop(heap)
    {heap, "a"} = H.pop(heap)
    assert len(heap) === 0
  end

  test "trie" do
    trie = Trie.new()
    trie = Trie.insert(trie, "hack")
    assert Trie.count(trie, "h") === 1
    assert Trie.count(trie, "ha") === 1
    assert Trie.count(trie, "hac") === 1
    assert Trie.count(trie, "hack") === 1
    trie = Trie.insert(trie, "hackerrank")
    assert Trie.count(trie, "h") === 2
    assert Trie.count(trie, "ha") === 2
    assert Trie.count(trie, "hac") === 2
    assert Trie.count(trie, "hack") === 2
    assert Trie.count(trie, "hacke") === 1
    assert Trie.count(trie, "hacker") === 1
    assert Trie.count(trie, "hackerr") === 1
    assert Trie.count(trie, "hackerra") === 1
    assert Trie.count(trie, "hackerran") === 1
    assert Trie.count(trie, "hackerrank") === 1
    assert Trie.count(trie, "s") === 0
    assert Trie.count(trie, "haj") === 0
    assert Trie.search(trie, "hack") === ["hack", "hackerrank"]
    assert Trie.search(trie, "ha") === ["hack", "hackerrank"]
    assert Trie.search(trie, "s") === []
    assert Trie.search(trie, "haj") === []
    trie =
      %Trie{key_fn: fn {key, _} -> key end}
      |> Trie.insert({"a", [1, 2]})
      |> Trie.insert({"b", nil})
      |> Trie.insert({"ab", [1]})
      |> Trie.insert({"aa", [2]})
      |> Trie.insert({"aaa", []})
    assert Trie.count(trie, "a") === 4
    assert Trie.count(trie, "b") === 1
    assert Trie.search(trie, "b") === [{"b", nil}]
    assert Trie.search(trie, "aa") === [{"aa", [2]}, {"aaa", []}]
    assert Trie.search(trie, "ba") === []
  end

  test "tree" do
    assert ~t{1 (2 3 6 7) (4 5)} === %T{elements: [1, [2, 3, 6, 7], [4, 5]]}
    assert ~t{1 (2 3 6 7) (4 5)}s === %T{elements: ["1", ["2", "3", "6", "7"], ["4", "5"]]}
    assert ~t{1 (2 3.5 6 7.75) (4.25 5)}f === %T{elements: [1.0, [2.0, 3.5, 6.0, 7.75], [4.25, 5.0]]}
  end

  test "binary tree" do
    assert ~t{1 (2 (3 5) 6) 4}b === %BT{elements: [1, [2, [3, 5], 6], 4]}
    try do
      ~t{1 (2 3 5 6 7)}b
    rescue
      e in RuntimeError -> assert e.message === "Not a binary tree"
    else
      _ -> assert false
    end

    tree = ~t{1 () (2 () (5 (3 () 4) 6))}b
    assert BT.preorder(tree) === [1, 2, 5, 3, 4, 6]
    assert BT.inorder(tree) === [1, 2, 3, 4, 5, 6]
    assert BT.postorder(tree) === [4, 3, 6, 5, 2, 1]
    assert BT.height(tree) === 4
    assert BT.height(~t{1}b) === 0
    assert BT.height(~t{1 2 3}b) === 1
    assert BT.height(~t{1 (2 3) 4}b) === 2
  end

  test "stack" do
    stack = St.new()
    assert empty?(stack)
    assert St.peek(stack) === nil
    try do
      St.pop(stack)
    rescue
      e in RuntimeError -> assert e.message === "Stack is empty!"
    else
      _ -> assert false
    end
    stack = St.push(stack, 1)
    assert St.peek(stack) === 1
    {1, stack} = St.pop(stack)
    stack = St.push(stack, 5)
    assert St.peek(stack) === 5
    stack = St.apply_on_top(stack, fn x -> x*x end)
    assert St.peek(stack) === 25
  end

  test "queue" do
    queue = Q.new() |> Q.enqueue(4)
    assert Q.peek(queue) === 4
    {4, queue} = Q.dequeue(queue)
    assert Q.peek(queue) === nil
    assert empty?(queue) === true
    try do
      Q.dequeue(queue)
    rescue
      e in RuntimeError -> assert e.message === "Queue is empty!"
    else
      _ -> assert false
    end
    queue =
      %Queue{resize_limit: 7}
      |> Q.enqueue(1)
      |> Q.enqueue(:a)
      |> Q.enqueue("b")
      |> Q.enqueue([])
      |> Q.enqueue(%{})
      |> Q.enqueue('a')
      |> Q.enqueue({})
      |> Q.enqueue({1,2})
    {1, queue} = Q.dequeue(queue)
    assert :array.size(queue.elements) === 8
    {:a, queue} = Q.dequeue(queue)
    assert :array.size(queue.elements) === 8
    {"b", queue} = Q.dequeue(queue)
    assert :array.size(queue.elements) === 5
  end

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
    try do
      Gr.edge(graph, 5, {1, 3}, nil)
    rescue
      e in RuntimeError -> assert e.message === "There is already an edge from 1 and to 3"
    else
      _ -> assert false
    end
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

  test "backtracking" do
    size = 4
    solutions = Algos.backtrack(
      1..size,
      fn solution ->
        Enum.count(solution) === size && Enum.uniq(solution) === solution
      end,
      fn solution ->
        Enum.uniq(solution) !== solution
      end
    )
    assert solutions === [
      [1, 2, 3, 4],
      [1, 2, 4, 3],
      [1, 3, 2, 4],
      [1, 3, 4, 2],
      [1, 4, 2, 3],
      [1, 4, 3, 2],
      [2, 1, 3, 4],
      [2, 1, 4, 3],
      [2, 3, 1, 4],
      [2, 3, 4, 1],
      [2, 4, 1, 3],
      [2, 4, 3, 1],
      [3, 1, 2, 4],
      [3, 1, 4, 2],
      [3, 2, 1, 4],
      [3, 2, 4, 1],
      [3, 4, 1, 2],
      [3, 4, 2, 1],
      [4, 1, 2, 3],
      [4, 1, 3, 2],
      [4, 2, 1, 3],
      [4, 2, 3, 1],
      [4, 3, 1, 2],
      [4, 3, 2, 1]
    ]
  end

  test "global" do
    assert G.get(:test) === nil
    G.set(:test, "true")
    assert G.get(:test) === "true"
    G.get_and_update(:test, &String.length/1)
    assert G.get(:test) === 4
    G.set_p(:test, nil)
    assert G.get(:test) === nil
    G.stop()
  end

  test "reader" do
    string = """
    1,2,3
    4,5,6
    7,8,9
    """
    assert In.string(string, column: ",") === [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"]
    ]
    assert In.string(string) === ["1,2,3", "4,5,6", "7,8,9"]
    string = "1#2#3;4#5#6;7#8#9;"
    assert In.string(string, line: ";", column: "#") === [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"]
    ]
    string = """
    1
    2
    3
    """
    assert In.string(string, to: :i) === [1, 2, 3]
    assert In.string(string, to: :f) === [1.0, 2.0, 3.0]
  end

  test "writer" do
    data = [[1,2],[3,4],[5,6]]
    assert Out.string(data) === "1,2\n3,4\n5,6"
    assert Out.string(data, line: "@", column: "!") === "1!2@3!4@5!6"
  end

  test "big reader" do
    {:ok, string} = StringIO.open("a,b,c\nd,e\nf,g,h,i")
    assert In.reduce_big_device(string, {}, fn x, acc -> Tuple.append(acc, x) end) === {
      ["a", "b", "c"], ["d", "e"], ["f", "g", "h", "i"]
    }
  end

end
