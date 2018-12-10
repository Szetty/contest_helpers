defmodule BinTree do
  defstruct elements: []

  def new(elements) do
    if binary?(elements) do
      %BinTree{elements: elements}
    else
      raise "Not a binary tree"
    end
  end

  def preorder(%BinTree{elements: elements}), do: do_preorder(elements)
  def inorder(%BinTree{elements: elements}), do: do_inorder(elements)
  def postorder(%BinTree{elements: elements}), do: do_postorder(elements)
  def height(%BinTree{elements: elements}), do: calculate_height(elements, 0)

  defp binary?([root, left, right]) when not is_list(root), do: binary?(left) && binary?(right)
  defp binary?([root, left]) when not is_list(root), do: binary?(left)
  defp binary?([root]) when not is_list(root), do: true
  defp binary?([]), do: true
  defp binary?(element) when is_list(element), do: false
  defp binary?(_), do: true

  defp do_preorder([root, left, right]) when not is_list(root), do: [root | do_preorder(left)] ++ do_preorder(right)
  defp do_preorder([root, left]) when not is_list(root), do: [root | do_preorder(left)]
  defp do_preorder([root]) when not is_list(root), do: [root]
  defp do_preorder([]), do: []
  defp do_preorder(root) when not is_list(root), do: [root]

  defp do_inorder([root, left, right]) when not is_list(root), do: do_inorder(left) ++ [root] ++ do_inorder(right)
  defp do_inorder([root, left]) when not is_list(root), do: [root | do_inorder(left)]
  defp do_inorder([root]) when not is_list(root), do: [root]
  defp do_inorder([]), do: []
  defp do_inorder(root) when not is_list(root), do: [root]

  defp do_postorder([root, left, right]) when not is_list(root), do: do_postorder(left) ++ do_postorder(right) ++ [root]
  defp do_postorder([root, left]) when not is_list(root), do: [root | do_postorder(left)]
  defp do_postorder([root]) when not is_list(root), do: [root]
  defp do_postorder([]), do: []
  defp do_postorder(root) when not is_list(root), do: [root]

  defp calculate_height([root, left, right], current_height) when not is_list(root), do: max(calculate_height(left, current_height + 1), calculate_height(right, current_height + 1))
  defp calculate_height([root, left], current_height) when not is_list(root), do: calculate_height(left, current_height + 1)
  defp calculate_height([root], current_height) when not is_list(root), do: current_height
  defp calculate_height([], current_height), do: current_height - 1
  defp calculate_height(root, current_height) when not is_list(root), do: current_height
end

defmodule Tree do

  defstruct elements: []

  def new(), do: %Tree{}
  def new(elements), do: %Tree{elements: elements}

  def sigil_t(string, []), do: parse(string)
  def sigil_t(string, [?s]), do: parse(string, Helpers.identity())
  def sigil_t(string, [?f]), do: parse(string, fn x -> x |> Float.parse |> elem(0) end)
  def sigil_t(string, [?b]), do: parse_binary(string)
  def sigil_t(string, [?b, ?s]), do: parse_binary(string, Helpers.identity())
  def sigil_t(string, [?b, ?f]), do: parse_binary(string, fn x -> x |> Float.parse |> elem(0) end)

  defp parse(string, mapper \\ &String.to_integer/1) do
    string
    |> String.codepoints
    |> parse("", Stack.new |> Stack.push([]), mapper)
    |> new
  end

  defp parse_binary(string, mapper \\ &String.to_integer/1) do
    string
    |> String.codepoints
    |> parse("", Stack.new |> Stack.push([]), mapper)
    |> BinTree.new
  end

  defp parse([], "", %Stack{elements: [tree]}, _mapper), do: tree |> Enum.reverse
  defp parse([], current_elem, %Stack{elements: [tree]}, mapper) do
    [current_elem |> mapper.() | tree] |> Enum.reverse
  end
  defp parse([char | rest], current_elem, stack, mapper) do
    {current_elem, stack} =
      case char do
        " " ->
          stack = put_elem_in_top_list_if_not_empty(stack, current_elem, mapper)
          {"", stack}
        "(" ->
          {"", Stack.push(stack, [])}
        ")" ->
          stack = put_elem_in_top_list_if_not_empty(stack, current_elem, mapper)
          {inner_list, stack} = Stack.pop(stack)
          inner_list = inner_list |> Enum.reverse
          stack = Stack.apply_on_top(stack, fn top_list -> [inner_list | top_list] end)
          {"", stack}
        char ->
          {current_elem <> char, stack}
    end
    parse(rest, current_elem, stack, mapper)
  end

  defp put_elem_in_top_list_if_not_empty(stack, current_elem, mapper) do
    if current_elem != "" do
      Stack.apply_on_top(stack, fn top_list -> [mapper.(current_elem) | top_list] end)
    else
      stack
    end
  end
end
