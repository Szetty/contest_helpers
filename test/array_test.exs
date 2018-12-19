defmodule ArrayTest do
  use ExUnit.Case
  import TestHelpers
  import Helpers
  import Array, only: :macros
  alias Array, as: A

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
    assert array[0..2] === [1, 4, nil]

    array = A.swap(array, 0, 1)
    assert array[0..2] === [4, 1, nil]

    array = put_in array[0..1], 2
    assert array[0..1] === [2, 2]

    assert array[99] === nil
    assert array[-50] === nil
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
    array = put_in array[2][2], 10
    assert array[2][2] === 10
    assert array[{0..1, 1}] === [2, 5]
    assert array[{0..1, 0..1}] === [1, 2, 4, 5]
    array = update_in array[{0..1, 1}], &(&1 + 1)
    assert array[{0..1, 1}] === [3, 6]
    array = update_in array[{0..1, 0..1}], &(&1 + 1)
    assert array[{0..1, 0..1}] === [2, 4, 5, 7]

    assert array[{-1, -1}] === nil
    assert array[{99, 99}] === nil
  end

  test "fixed array" do
    array = A.new(10, 0)
    assert array[0] === 0
    assert array[9] === 0
    assert_error "Index out of bounds, with index 10", do: array[10]
  end

  test "fixed 2d array" do
    array = A.new2d(2, 2, :a)
    assert array[0][0] === :a
    assert array[1][1] === :a
    assert_error "Index out of bounds, with index 2", do: array[2]
    assert_error "Index out of bounds, with index 3", do: array[1][3]
  end

  test "to_list" do
    assert A.to_list(A.new([1, 7, 9, 2, 5])) === [1, 7, 9, 2, 5]
    assert A.to_list(A.new(3, :l)) === [:l, :l, :l]
    assert A.to_list(A.new2d(2, 2, 0)) === [[0, 0], [0, 0]]
    assert A.to_list(A.new([{1, 2}, {3, 4}])) === [{1, 2}, {3, 4}]
    assert A.to_list(A.new([[1, 2], [3, 4]])) === [[1, 2], [3, 4]]
    grid = Reader.string("..|.#;.|#..;..#..;.||..;.....", line: ";", column: "")
    assert A.to_list(A.new(grid)) === grid
  end

  test "map" do
    a =
      A.new([1, 2, 3, 4, 5])
      |> A.map(fn _idx, el -> el * el end)
      |> A.to_list
    assert a === [1, 4, 9, 16, 25]
    a =
      A.new([[1, 2], [3, [4]], 5])
      |> A.map_rec(fn _idx, el -> el * el end)
      |> A.to_list
    assert a === [[1, 4], [9, [16]], 25]
    a =
      A.new([[1, 2], [3, 4], [5, 6]])
      |> A.map_rec(fn [j, i], _el -> i + 2 * j end)
      |> A.to_list
    assert a === [[0, 2], [1, 3], [2, 4]]
  end
end
