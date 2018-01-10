defmodule RaiEx.Helpers do
  @moduledoc false

  def min_recv(), do: Application.get_env(:rai_dice, :min_receive, 1_000_000_000_000_000_000_000_000)

  def if_string_hex_to_binary([]), do: []
  def if_string_hex_to_binary(binaries) when is_list(binaries) do
    [binary | rest] = binaries
    [if_string_hex_to_binary(binary) | if_string_hex_to_binary(rest)]
  end
  def if_string_hex_to_binary(binary) do
    if String.valid?(binary), do: Base.decode16!(binary), else: binary
  end


  def reverse(binary) when is_binary(binary), do: do_reverse(binary, <<>>)
  defp do_reverse(<<>>, acc), do: acc
  defp do_reverse(<< x :: binary-size(1), bin :: binary >>, acc), do: do_reverse(bin, x <> acc)

  def left_pad_binary(binary, bits) do
    <<0::size(bits), binary::bitstring>>
  end

  def right_pad_binary(binary, bits) do
    <<binary::bitstring, 0::size(bits)>>
  end
end