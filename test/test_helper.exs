ExUnit.start(exclude: :skip)

defmodule TestHelper do
  defmacro skip_offline() do
    case RaiEx.available_supply() do
      {:error, :econnrefused} ->
        quote do: @tag :skip
      _ ->
        quote do: @tag :dont_skip
    end
  end
end