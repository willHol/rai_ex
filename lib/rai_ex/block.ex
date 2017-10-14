defmodule RaiEx.Block do
  @moduledoc """
  The block struct and associated functions.

  ## Fields

    * `type` - the block type, default: "send"
    * `previous` - the previous block hash, e.g. 9F1D53E732E48F25F94711D5B22086778278624F715D9B2BEC8FB81134E7C904
    * `destination` - the destination address, e.g. xrb_34bmpi65zr967cdzy4uy4twu7mqs9nrm53r1penffmuex6ruqy8nxp7ms1h1
    * `balance` - the amount to send, measured in RAW
    * `work` - the proof of work, e.g. "266063092558d903"
    * `signature` - the signed block digest/hash
    * `hash` - the block digest/hash
    * `source` - the source of the block
    * `state` - the state of the block, can be: `:unsent` or `:sent`

  """

  import RaiEx.Helpers

  alias RaiEx.Block

  @derive {Poison.Encoder, except: [:state, :source, :hash]}
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
  Allows the use of `Enum.into` for inserting map values into a `Block`.
  """
  defimpl Collectable, for: Block do
    def into(original) do
      {original, fn
        block, {:cont, {k, v}} when is_atom(k) -> %{block | k => v}
        block, {:cont, {k, v}} when is_binary(k) -> %{block | String.to_atom(k) => v}
        block, :done -> block
        _, :halt -> :ok
      end}
    end
  end

  @doc """
  Signs a block.
  """
  def sign_block(%Block{
    previous: previous,
    destination: destination,
    balance: balance,
  } = block, priv_key, pub_key \\ nil) do
    # Converts binaries if necessary
    [priv_key, pub_key, previous, balance] =
      if_string_hex_to_binary([priv_key, pub_key, previous, balance])

    hash = Blake2.hash2b(previous <> RaiEx.Tools.address_to_public(destination) <> balance, 32)
    signature  = Ed25519.signature(hash, priv_key, pub_key)

    %{block | hash: Base.encode16(hash), signature: Base.encode16(signature)}
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
    {:ok, %{"work" => work}} = RaiEx.work_generate(previous)

    RaiEx.process(Poison.encode!(%{block | work: work}))
  end
  def send_block(%Block{}), do: {:error, :already_sent}

  def from_map(%{} = map) do
    Enum.into(map, %Block{})
  end

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