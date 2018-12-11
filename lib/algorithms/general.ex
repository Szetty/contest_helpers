defmodule Algorithms.General do

  defmodule PartialSums do
    defstruct sums: nil, calc: nil

    def new(sizex, sizey, fun) do
      a = Array.new2d(sizex + 1, sizey + 1)
      sums =
      (for x <- 0..sizex, do: for y <- 0..sizey, do: {x, y})
      |> List.flatten
      |> Enum.reduce(a, fn {x, y}, a ->
        if x === 0 || y === 0 do
          put_in(a[x][y], 0)
        else
          put_in(a[x][y], fun.(x - 1, y - 1) + a[x - 1][y] + a[x][y - 1] - a[x - 1][y - 1])
        end
      end)
      calc = fn xs..xe, ys..ye ->
        xe = Kernel.min(xe + 1, sizex)
        ye = Kernel.min(ye + 1, sizey)
        sums[xe][ye] - sums[xe][ys] - sums[xs][ye] + sums[xs][ys]
      end
      %PartialSums{sums: sums, calc: calc}
    end
  end

  def backtrack(data, accept_fn, reject_fn) do
    G.set(:accept, accept_fn)
    G.set(:reject, reject_fn)
    G.set(:data, data)
    solutions = do_backtrack([]) |> Enum.map(&Kernel.elem(&1, 0))
    G.stop()
    solutions
  end

  def partial_sums(sizex, sizey, fun) when is_function(fun, 2) do
    PartialSums.new(sizex, sizey, fun)
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
