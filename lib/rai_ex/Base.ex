defmodule RaiEx.Base do
  @mappings (
    {_i, mappings} =
      "13456789abcdefghijkmnopqrstuwxyz"
      |> String.split("")
      |> Enum.drop(-1)
      |> Enum.reduce({0, %{}}, fn letter, {i, map} -> 
           {i + 1, Map.put(map, letter, <<i :: size(5)>>)}
         end)

    mappings
  )

  def decode!(string) do
    string
    |> String.split("")
    |> Enum.drop(-1)
    |> Enum.reduce(<<>>, &(<<&2::bitstring, @mappings[&1]::bitstring>>))
  end

  def decode(string) do
    try do
      res = decode!(string)
      {:ok, res}
    rescue
      e in ArgumentError -> {:error, :badarg}
    end
  end

  def character_mappings, do: @mappings
end