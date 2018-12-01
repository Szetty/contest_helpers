defmodule ContestHelpersTest do
  use ExUnit.Case
  doctest ContestHelpers

  test "greets the world" do
    assert ContestHelpers.hello() == :world
  end
end
