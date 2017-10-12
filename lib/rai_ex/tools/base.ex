defmodule RaiEx.Tools.Base do
  @moduledoc """
  This module provides functions for dealing with encoding and decoding, RaiDice base32.
  """

  @mappings (
    {_i, mappings} =
      "13456789abcdefghijkmnopqrstuwxyz"
      |> String.split("", trim: true)
      |> Enum.reduce({0, %{}}, fn letter, {i, map} -> 
           {
            i + 1,
            Map.merge(map, %{letter => <<i :: size(5)>>, <<i :: size(5)>> => letter})
          }
         end)

    mappings
  )

  @doc """
  Returns true if the binary can be encoded into base32.
  """
  def binary_valid?(binary), do: rem(bit_size(binary), 5) === 0

  @doc """
  Decodes a base32 string into its bitstring form.

  Raises `Elixir.ArgumentError` if the string is invalid.

  ## Examples

      iex> decode!("34bmipzf")
      <<8, 147, 56, 91, 237>>

      iex> decode!("bmg2")
      ** (Elixir.ArgumentError)
      
  """
  def decode!(string) do
    string
    |> String.split("", trim: true)
    |> Enum.reduce(<<>>, &(<<&2::bitstring, @mappings[&1]::bitstring>>))
  end

  @doc """
  Same as `RaiEx.Base.decode!`, except returns a results tuple.

  ## Examples

      iex> decode("34bmipzf")
      {:ok, <<8, 147, 56, 91, 237>>}

      iex> decode("bmg2")
      {:error, :badarg}

  """
  def decode(string) do
    try do
      {:ok, decode!(string)}
    rescue
      _e in ArgumentError -> {:error, :badarg}
    end
  end

  @doc """
  Encodes a bitstring/binary into its base32 form.

  Raises `Elixir.ArgumentError` if the bitstring/binary is invalid.

  ## Examples

      iex> encode(<<8, 147, 56, 91, 237>>)
      "34bmipzf"

      iex> encode(<<8, 5>>)
      ** (Elixir.ArgumentError)

  """
  def encode!(bitstring, acc \\ "")
  def encode!(<<>>, acc), do: acc
  def encode!(invalid, _acc) when bit_size(invalid) < 5 do
    raise ArgumentError, message: "bit_size must be a multiple of 5"
  end
  def encode!(bitstring, acc) do
    <<letter::size(5), rest::bitstring>> = bitstring
    encode!(rest, acc <> @mappings[<<letter::size(5)>>])
  end

  @doc """
  Same as `RaiEx.Base.encode!`, except returns a results tuple.

  ## Examples

      iex> encode(<<8, 147, 56, 91, 237>>)
      {:ok, "34bmipzf"}

      iex> encode(<<8, 5>>)
      {:error, :badarg}

  """
  def encode(bitstring) do
    try do
      {:ok, encode!(bitstring)}
    rescue
      _e in ArgumentError -> {:error, :badarg}
    end
  end

  @doc """
  Returns the duplexed map.

  ## Example

      %{"1" => <<0::size(5)>>, <0::size(5)>> => "1"}

  """
  def character_mappings, do: @mappings
end