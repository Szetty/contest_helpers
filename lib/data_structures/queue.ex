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
