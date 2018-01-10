defmodule RaiEx.Tools.Base32 do
  @moduledoc """
  This module provides functions for dealing with encoding and decoding, RaiDice base32.
  """

  defp char_to_bin("1"), do: <<0::5>>
  defp char_to_bin("3"), do: <<1::5>>
  defp char_to_bin("4"), do: <<2::5>>
  defp char_to_bin("5"), do: <<3::5>>
  defp char_to_bin("6"), do: <<4::5>>
  defp char_to_bin("7"), do: <<5::5>>
  defp char_to_bin("8"), do: <<6::5>>
  defp char_to_bin("9"), do: <<7::5>>
  defp char_to_bin("a"), do: <<8::5>>
  defp char_to_bin("b"), do: <<9::5>>
  defp char_to_bin("c"), do: <<10::5>>
  defp char_to_bin("d"), do: <<11::5>>
  defp char_to_bin("e"), do: <<12::5>>
  defp char_to_bin("f"), do: <<13::5>>
  defp char_to_bin("g"), do: <<14::5>>
  defp char_to_bin("h"), do: <<15::5>>
  defp char_to_bin("i"), do: <<16::5>>
  defp char_to_bin("j"), do: <<17::5>>
  defp char_to_bin("k"), do: <<18::5>>
  defp char_to_bin("m"), do: <<19::5>>
  defp char_to_bin("n"), do: <<20::5>>
  defp char_to_bin("o"), do: <<21::5>>
  defp char_to_bin("p"), do: <<22::5>>
  defp char_to_bin("q"), do: <<23::5>>
  defp char_to_bin("r"), do: <<24::5>>
  defp char_to_bin("s"), do: <<25::5>>
  defp char_to_bin("t"), do: <<26::5>>
  defp char_to_bin("u"), do: <<27::5>>
  defp char_to_bin("w"), do: <<28::5>>
  defp char_to_bin("x"), do: <<29::5>>
  defp char_to_bin("y"), do: <<30::5>>
  defp char_to_bin("z"), do: <<31::5>>

  defp bin_to_char(<<0::5>>), do: "1"
  defp bin_to_char(<<1::5>>), do: "3"
  defp bin_to_char(<<2::5>>), do: "4"
  defp bin_to_char(<<3::5>>), do: "5"
  defp bin_to_char(<<4::5>>), do: "6"
  defp bin_to_char(<<5::5>>), do: "7"
  defp bin_to_char(<<6::5>>), do: "8"
  defp bin_to_char(<<7::5>>), do: "9"
  defp bin_to_char(<<8::5>>), do: "a"
  defp bin_to_char(<<9::5>>), do: "b"
  defp bin_to_char(<<10::5>>), do: "c"
  defp bin_to_char(<<11::5>>), do: "d"
  defp bin_to_char(<<12::5>>), do: "e"
  defp bin_to_char(<<13::5>>), do: "f"
  defp bin_to_char(<<14::5>>), do: "g"
  defp bin_to_char(<<15::5>>), do: "h"
  defp bin_to_char(<<16::5>>), do: "i"
  defp bin_to_char(<<17::5>>), do: "j"
  defp bin_to_char(<<18::5>>), do: "k"
  defp bin_to_char(<<19::5>>), do: "m"
  defp bin_to_char(<<20::5>>), do: "n"
  defp bin_to_char(<<21::5>>), do: "o"
  defp bin_to_char(<<22::5>>), do: "p"
  defp bin_to_char(<<23::5>>), do: "q"
  defp bin_to_char(<<24::5>>), do: "r"
  defp bin_to_char(<<25::5>>), do: "s"
  defp bin_to_char(<<26::5>>), do: "t"
  defp bin_to_char(<<27::5>>), do: "u"
  defp bin_to_char(<<28::5>>), do: "w"
  defp bin_to_char(<<29::5>>), do: "x"
  defp bin_to_char(<<30::5>>), do: "y"
  defp bin_to_char(<<31::5>>), do: "z"

  @doc """
  Returns true if the binary can be encoded into base32.
  """
  def binary_valid?(binary), do: rem(bit_size(binary), 5) === 0

  @doc """
  Decodes a base32 string into its bitstring form.

  Raises `ArgumentError` if the string is invalid.

  ## Examples

      iex> decode!("34bmipzf")
      <<8, 147, 56, 91, 237>>

      iex> decode!("bmg2")
      ** (Elixir.ArgumentError)
      
  """
  def decode!(string) do
    string
    |> String.split("", trim: true)
    |> Enum.reduce(<<>>, &(<<&2::bitstring, char_to_bin(&1)::bitstring>>))
  end

  @doc """
  Same as `decode!`, except returns a results tuple.

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

  Raises `ArgumentError` if the bitstring/binary is invalid.

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
    encode!(rest, acc <> bin_to_char(<<letter::size(5)>>))
  end

  @doc """
  Same as `encode!`, except returns a results tuple.

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
end