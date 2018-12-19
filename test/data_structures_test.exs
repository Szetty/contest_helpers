defmodule DataStructuresTest do
  use ExUnit.Case
  use DataStructures
  import TestHelpers

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
    assert_error "Not a binary tree", do: ~t{1 (2 3 5 6 7)}b

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
    assert_error "Stack is empty!", do: St.pop(stack)
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
    assert_error "Queue is empty!", do: Q.dequeue(queue)
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
    assert In.string("..|.#;.|#..;..#..;.||..;.....", line: ";", column: "") === [
      [".", ".", "|", ".", "#"],
      [".", "|", "#", ".", "."],
      [".", ".", "#", ".", "."],
      [".", "|", "|", ".", "."],
      [".", ".", ".", ".", "."]
    ]
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
