defmodule HelpersTest do
  use ExUnit.Case
  import Helpers

  test "recursive anonymous function" do
    factorial = fix fn f ->
      fn
        0 -> 1
        1 -> 1
        n -> n * f.(n - 1)
      end
    end

    assert factorial.(2) === 2
    assert factorial.(3) === 6
    assert factorial.(5) === 120

    remove_dup = fix fn f ->
      fn
        [] -> []
        [_] = l -> l
        [h1, h2 | t] ->
          if h1 === h2 do
            f.(t)
          else
            [h1 | f.([h2 | t])]
          end
      end
    end

    assert remove_dup.([1, 1, 2, 3]) === [2, 3]
    assert remove_dup.([3, 3, 1]) === [1]
    assert remove_dup.([1, 2, 3]) === [1, 2, 3]
  end

  test "levenhstein" do
    assert levenhstein("s", "s") === 0
    assert levenhstein("s", "k") === 1
    assert levenhstein("ss", "ss") === 0
    assert levenhstein("sk", "sj") === 1
    assert levenhstein("kitten", "sitten") === 1
    assert levenhstein("kitten", "sitting") === 3
  end

  test "top" do
    assert top([1, 2, 3, 4, 5, 6]) === [1]
    assert top([1, 2, 3, 4, 5, 6], 2) === [1, 2]
    assert top([4, 3, 2, 6, 1, 5], 3) === [1, 2, 3]
    assert top(
      [{1, 3}, {2, 1}, {0, 5}, {4, 4}],
      3,
      fn {x, y}, {a, b} -> x + y < a + b end
    ) === [{2, 1}, {1, 3}, {0, 5}]
  end

  test "transformations" do
    assert to_i("123") === 123
    assert to_i(:"444") === 444
    assert to_i(4.1) === 4
    assert to_i(4.8) === 4
    assert to_i('123') === 123
    assert to_i(10) === 10
    assert to_i(true) === 1
    assert to_i(false) === 0

    assert to_f("123.25") === 123.25
    assert to_f(:"444.75") === 444.75
    assert to_f(4.1) === 4.1
    assert to_f(4.8) === 4.8
    assert to_f(10) === 10.0
    assert to_f(true) === 1.0
    assert to_f(false) === 0.0
  end

end
