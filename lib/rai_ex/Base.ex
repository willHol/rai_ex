defmodule RaiEx.Base do
  def generate_mappings do
    {_i, mappings} =
      "13456789abcdefghijkmnopqrstuwxyz"
      |> String.split("")
      |> Enum.drop(-1)
      |> Enum.reduce({0, %{}}, fn letter, {i, map} -> 
           {i + 1, Map.put(map, letter, <<i :: size(5)>>)}
         end)

    mappings
  end

  def decode!(string) do
    m = generate_mappings()

    string
    |> String.split("")
    |> Enum.drop(-1)
    |> Enum.reduce(<<>>, &(<<&2::bitstring, m[&1]::bitstring>>))
  end

  def decode(string) do
    try do
      res = decode!(string)
      {:ok, res}
    rescue
      e in ArgumentError -> {:error, :badarg}
    end
  end
end