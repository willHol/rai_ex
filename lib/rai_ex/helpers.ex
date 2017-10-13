defmodule RaiEx.Helpers do
  @doc """
  Converts hex string(s) to binary if necessary.
  """
  def if_string_hex_to_binary([]), do: []
  def if_string_hex_to_binary(binaries) when is_list(binaries) do
    [binary | rest] = binaries
    [if_string_hex_to_binary(binary) | if_string_hex_to_binary(rest)]
  end
  def if_string_hex_to_binary(binary) do
    if String.valid?(binary), do: Base.decode16!(binary), else: binary
  end

  @doc """
  Reverses a binary.
  """
  def reverse(binary) when is_binary(binary), do: do_reverse(binary, <<>>)
  def do_reverse(<<>>, acc), do: acc
  def do_reverse(<< x :: binary-size(1), bin :: binary >>, acc), do: do_reverse(bin, x <> acc)

  @doc """
  Left pads a binary.
  """
  def pad_binary(binary, bits) do
    <<0::size(bits), binary::bitstring>>
  end
end