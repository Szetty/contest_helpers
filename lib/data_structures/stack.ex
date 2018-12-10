defmodule Stack do
  defstruct elements: []

  def new, do: %Stack{}

  def push(%Stack{elements: elements} = stack, element) do
    %{stack | elements: [element | elements]}
  end

  def pop(%Stack{elements: []}), do: raise("Stack is empty!")
  def pop(%Stack{elements: [top | rest]} = stack) do
    {top, %{stack | elements: rest}}
  end

  def peek(%Stack{elements: []}), do: nil
  def peek(%Stack{elements: [top | _]}), do: top

  def apply_on_top(%Stack{elements: []}), do: raise("Stack is empty!")
  def apply_on_top(%Stack{elements: [top | rest]} = stack, fun) do
    %{stack | elements: [fun.(top) | rest]}
  end

  def is_empty?(%Stack{elements: elements}), do: elements === []
end