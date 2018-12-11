defmodule AlgorithmsTest do
  use ExUnit.Case
  alias Algorithms.General, as: Algos

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

  test "partial sums" do
    a = Array.new([
      [1, 2, 3, 4],
      [4, 3, 2, 1],
      [1, 1, 1, 1],
      [1, -1, -1, 1],
    ])
    partial_sums = Algos.partial_sums(4, 4, fn x, y -> a[x][y] end)
    assert Array.to_list(partial_sums.sums) === [
      [0, 0, 0, 0, 0],
      [0, 1, 3, 6, 10],
      [0, 5, 10, 15, 20],
      [0, 6, 12, 18, 24],
      [0, 7, 12, 17, 24],
    ]
    assert partial_sums.calc.(1..2, 1..2) === 7
    assert partial_sums.calc.(2..3, 1..3) === 2
    assert partial_sums.calc.(3..3, 3..3) === 1
    assert partial_sums.calc.(3..10, 3..10) === 1
  end
end
