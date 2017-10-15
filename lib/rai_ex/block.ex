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

  ## Send a block

      alias RaiEx.Tools
      alias RaiEx.Block

      # Generate a private and public keypair from a wallet seed
      {priv, pub} = Tools.seed_account("9F1D53E732E48F25F94711D5B22086778278624F715D9B2BEC8FB81134E7C904", 0)

      # Derives an "xrb_" address
      address = Tools.create_address!(pub)
      
      # Get the previous block hash
      {:ok, %{"frontier" => block_hash}} = RaiEx.account_info(address)

      # Somewhat counterintuitively 'balance' refers to the new balance not the
      # amount to be sent
      block = %Block{
        previous: block_hash,
        destination: "xrb_1aewtdjz8knar65gmu6xo5tmp7ijrur1fgtetua3mxqujh5z9m1r77fsrpqw",
        balance: 0
      }

      # Signs and broadcasts the block to the network
      block |> Block.sign(priv, pub) |> Block.send()

  Now *all the funds* from the first account have been transferred to:

  `"xrb_1aewtdjz8knar65gmu6xo5tmp7ijrur1fgtetua3mxqujh5z9m1r77fsrpqw"`

  ## Receive the most recent pending block.

      {:ok, %{"blocks" => [block_hash]}} = RaiEx.pending(address, 1)
      {:ok, %{"frontier" => frontier}} = RaiEx.account_info(address)

      block = %Block{
        type: "receive",
        previous: frontier,
        source: block_hash
      }

      block |> Block.sign(priv, pub) |> Block.process

  """

  import RaiEx.Helpers

  alias RaiEx.Block

  @derive {Poison.Encoder, except: [:state, :hash]}
  defstruct [
    type: "send",
    previous: nil,
    destination: nil,
    balance: 0,
    work: nil,
    source: nil,
    signature: nil,
    hash: nil,
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
  Processes the block. Automatically invokes the correct processing function.
  """
  def process(%Block{type: "send"} = block), do: send(block)
  def process(%Block{type: "receive"} = block), do: recv(block)

  @doc """
  Signs the block. Automatically invokes the correct signing function.
  """
  def sign(%Block{type: "send"} = block, priv_key, pub_key \\ nil) do
    sign_send(block, priv_key, pub_key)
  end
  def sign(%Block{type: "receive"} = block, priv_key, pub_key) do
    sign_recv(block, priv_key, pub_key)
  end

  @doc """
  Signs a send block.
  """
  def sign_send(%Block{
    previous: previous,
    destination: destination,
    balance: balance,
  } = block, priv_key, pub_key \\ nil) do
    # Converts binaries if necessary
    [priv_key, pub_key, previous] =
      if_string_hex_to_binary([priv_key, pub_key, previous])

    hash = Blake2.hash2b(previous <> RaiEx.Tools.address_to_public(destination) <> <<balance::size(128)>>, 32)
    signature = Ed25519.signature(hash, priv_key, pub_key)

    %{block | hash: Base.encode16(hash), signature: Base.encode16(signature)}
  end

  @doc """
  Signs a receive block.
  """
  def sign_recv(%Block{
    previous: previous,
    source: source
  } = block, priv_key, pub_key \\ nil) do
    [priv_key, pub_key, previous, source] =
      if_string_hex_to_binary([priv_key, pub_key, previous, source])

    hash = Blake2.hash2b(previous <> source, 32)
    signature = Ed25519.signature(hash, priv_key, pub_key)

    %{block | hash: Base.encode16(hash), signature: Base.encode16(signature),
      source: Base.encode16(source)}
  end

  @doc """
  Sends a block.
  """
  def send(%Block{hash: nil}), do: raise ArgumentError
  def send(%Block{signature: nil}), do: raise ArgumentError
  def send(%Block{
    type: type,
    previous: previous,
    destination: destination,
    balance: balance,
    work: work,
    hash: hash,
    signature: signature,
    state: :unsent
  } = block) do
    {:ok, %{"work" => work}} = RaiEx.work_generate(previous)

    block = %{block | work: work, state: :sent}

    {:ok, %{}} = RaiEx.process(Poison.encode!(block))

    block
  end
  def send(%Block{}), do: {:error, :already_sent}

  @doc """
  Receives a block.
  """
  def recv(%Block{destination: destination, signature: signature, source: source, previous: previous} = block) do
    {:ok, %{"work" => work}} = RaiEx.work_generate(previous)

    {:ok, %{}} = RaiEx.process(Poison.encode!(%{
      previous: previous,
      signature: signature,
      source: source,
      type: "receive",
      work: work
    }))

    %{block | work: work}
  end

  @doc """
  Generates a `RaiEx.Block` struct from a map.
  """
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