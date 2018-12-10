defmodule Heap do
  defstruct elems: %Array{}, comp: &Kernel.</2

  def new(comp \\ &Kernel.</2) do
    %Heap{comp: comp}
  end

  def peek(heap) do
    heap.elems[0]
  end

  def push(heap, elem) do
    index = size(heap)
    heap
    |> update(index, elem)
    |> heapify_up(index)
  end

  def pop(heap) do
    elem = heap.elems[0]
    heap =
      heap
      |> update(0, heap.elems[last_index(heap)])
      |> delete(last_index(heap))
      |> heapify_down(0)
    {heap, elem}
  end

  def size(heap), do: Enum.count(heap.elems)

  def heapify(enumerable, comp \\ &Kernel.</2), do: Enum.reduce(enumerable, Heap.new(comp), &Heap.push(&2, &1))

  defp heapify_up(heap, index) do
    parent_index = parent(index)
    elem = heap.elems[index]
    parent = heap.elems[parent_index]
    cond do
      root?(index) || !heap.comp.(elem, parent) -> heap
      true ->
        heap
        |> update(index, parent)
        |> update(parent_index, elem)
        |> heapify_up(parent_index)
    end
  end

  defp heapify_down(heap, index) do
    current = heap.elems[index]
    {child_index, child} = next_child(heap, index)
    cond do
      leaf?(heap, index) || heap.comp.(current, child) -> heap
      true ->
        heap
        |> update(index, child)
        |> update(child_index, current)
        |> heapify_down(child_index)
    end
  end

  defp update(%Heap{elems: elems} = heap, index, elem), do: %{heap | elems: put_in(elems[index], elem)}
  defp delete(%Heap{elems: elems} = heap, index), do: %{heap | elems: (pop_in(elems[index]) |> elem(1))}

  defp next_child(heap, index) do
    left_index = left_child(index)
    right_index = right_child(index)
    left = heap.elems[left_index]
    right = heap.elems[right_index]
    cond do
      left === nil -> {nil, nil}
      right === nil -> {left_index, left}
      heap.comp.(left, right) -> {left_index, left}
      true -> {right_index, right}
    end
  end

  defp parent(index), do: (index / 2) |> trunc
  defp left_child(index), do: 2 * index + 1
  defp right_child(index), do: 2 * index + 2

  defp leaf?(heap, index), do: (index * 2) >= last_index(heap)
  defp root?(index), do: index === 0

  defp last_index(heap), do: size(heap) - 1
end
