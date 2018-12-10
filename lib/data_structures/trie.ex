defmodule Trie do
  defstruct value: %{}, key_fn: nil
  @meta_keys [:size, :element]

  def new(), do: %Trie{}

  def insert(%Trie{value: value} = trie, element) do
    key = apply_key_fn(trie, element)
    map = do_insert(value, key |> String.codepoints, element)
    %{trie | value: map}
  end

  def count(%Trie{value: value}, prefix) do
    do_count(value, String.codepoints(prefix))
  end

  def search(%Trie{value: value}, prefix) do
    do_find(value, String.codepoints(prefix))
  end

  defp apply_key_fn(%Trie{key_fn: nil}, element), do: Helpers.identity.(element)
  defp apply_key_fn(%Trie{key_fn: key_fn}, element) when is_function(key_fn, 1), do: key_fn.(element)

  defp do_insert(%{} = map, [], element), do: Map.put(map, :element, element)
  defp do_insert(%{} = map, [char | rest], element) do
    size = Map.get(map, :size, 0)
    submap =
      case map[char] do
        nil ->
          rest
          |> Enum.reverse
          |> Enum.reduce(
            %{size: 1, element: element}, fn x, acc ->
            Map.put(%{size: 1}, x, acc)
          end)

        %{} = sub_map ->
          do_insert(sub_map, rest, element)
      end
    map
    |> Map.put(char, submap)
    |> Map.put(:size, size + 1)
  end

  defp do_count(%{size: size}, []), do: size
  defp do_count(%{} = map, [char | rest]) do
    case map[char] do
      nil -> 0
      %{} = sub_map -> do_count(sub_map, rest)
    end
  end

  defp do_find(%{} = map, []), do: do_build_list(map)
  defp do_find(%{} = map, [char | rest]) do
    case map[char] do
      nil -> []
      %{} = sub_map -> do_find(sub_map, rest)
    end
  end

  defp do_build_list(%{} = map) do
    case Map.get(map, :element, nil) do
      nil -> []
      element -> [element]
    end
    |> Kernel.++(
      map
      |> Enum.filter(fn {key, _} -> !Enum.member?(@meta_keys, key) end)
      |> Enum.map(fn {_, sub_map} -> do_build_list(sub_map) end)
      |> List.flatten
    )
  end
end
