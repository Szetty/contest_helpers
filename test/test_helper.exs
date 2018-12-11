ExUnit.start()

defmodule TestHelpers do
  defmacro assert_error(message, do: block) do
    quote do
      try do
        unquote(block)
      rescue
        e in RuntimeError -> assert e.message === unquote(message)
      else
        _ -> assert false
      end
    end
  end
end
