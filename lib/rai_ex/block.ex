defmodule RaiEx.Block do
  @moduledoc """
  The block struct and associated functions.
  """

  import RaiEx.Helpers

  alias RaiEx.Block

  @derive {Poison.Encoder, except: [:state]}
  defstruct [
    type: "send",
    previous: nil,
    destination: nil,
    balance: 0,
    work: nil,
    signature: nil,
    hash: nil,
    source: nil,
    state: :unsent
  ]

  @doc """
  Signs a block.
  """
  def sign_block(%Block{
    previous: previous,
    destination: destination,
    balance: balance,
  } = block, priv_key, pub_key \\ nil) do
    # Converts binaries if necessary
    [priv_key, pub_key, previous, destination, balance] =
      if_string_hex_to_binary([priv_key, pub_key, previous, destination, balance])

    hash = Blake2.hash2b(previous <> destination <> balance, 32)
    signature  = Ed25519.signature(hash, priv_key, pub_key)

    %{block | hash: hash, signature: signature}
  end

  @doc """
  Sends a block.
  """
  def send_block(%Block{hash: nil}), do: raise ArgumentError
  def send_block(%Block{signature: nil}), do: raise ArgumentError
  def send_block(%Block{
    type: type,
    previous: previous,
    destination: destination,
    balance: balance,
    source: source,
    work: work,
    hash: hash,
    signature: signature,
    state: :unsent
  } = block) do
    {:ok, %{"work" => work}} = RaiEx.work_generate(hash)

    RaiEx.process(%{block | work: work})
  end
  def send_block(%Block{}), do: {:error, :already_sent}

  @doc false
  def generate_work(%Block{hash: nil}), do: :not_hashed
  def generate_work(%Block{hash: hash}) do
    max_iterations = 274877906945

    try do
      1..max_iterations
      |> Enum.reduce(:notfound, fn i, result ->
        IO.puts i
        if work_valid?(<<i::size(64)>>, hash) do
          throw <<i::size(64)>>
        end
      end)
    catch
      work -> work
    end
  end

  @doc false
  def work_valid?(work, hash) do
    bin = Blake2.hash2b(work <> hash, 8)
    <<a, b, c, d, _rest::binary>> = reverse(bin)

    a == 255
  end
end