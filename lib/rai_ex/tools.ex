defmodule RaiEx.Tools do
  @moduledoc """
  This module is provides convenience functions for
  working with payments.
  """

  alias RaiEx.Tools
  alias RaiEx.Block

  @delay 200

  @doc """
  Generates a wallet seed.
  """
  def seed do
    << int :: size(64) >> = :crypto.strong_rand_bytes(8)
    int
  end

  @doc """
  Changes the password for the `wallet`.

  ## Examples

      iex> change_password(wallet, current_pwd, new_pwd)
      {:ok, wallet}

      iex> change_password(wallet, invalid_pwd, new_pwd)
      {:error, reason}

  """
  def change_password(wallet, current_pwd, password) do
    with {:ok, %{"valid" => "1"}} <- RaiEx.password_enter(wallet, current_pwd),
         {:ok, %{"changed" => "1"}} <- RaiEx.password_change(wallet, password)
         do {:ok, wallet} else {_, reason} -> {:error, reason} end
  end

  @doc """
  Creates a new encrypted wallet. Locks it with `password`.
  """
  def wallet_create_encrypted(password) do
    with {:ok, %{"wallet" => wallet}} <- RaiEx.wallet_create,
         _ <- :timer.sleep(@delay),
         {:ok, ^wallet} <- change_password(wallet, "", password)
         do {:ok, wallet} else {_, reason} -> {:error, reason} end
  end

  @doc """
  Inserts a new adhoc key into `wallet`.
  """
  def wallet_add_adhoc(wallet) do
    with {:ok, %{"private" => priv, "public" => pub, "account" => acc}} <- RaiEx.key_create,
         {:ok, %{"account" => ^acc}} <- RaiEx.wallet_add(wallet, priv)
         do {:ok, %{"private" => priv, "public" => pub, "account" => acc}} else {_, reason} -> {:error, reason} end
  end

  @doc """
  Unlocks the given wallet with its `password`.
  """
  def unlock_wallet(wallet, password) do
    case RaiEx.password_enter(wallet, password) do
      {:ok, %{"valid" => "1"}} ->
        {:ok, wallet}
      {:ok, %{"valid" => "0"}} ->
        {:error, :invalid}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Locks the given wallet.
  """
  def lock_wallet(wallet) do
    case RaiEx.password_enter(wallet, "") do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  @doc """
  Calculates and compares the checksum on an address, returns a boolean.

  ## Examples

      iex> address_valid("xrb_34bmpi65zr967cdzy4uy4twu7mqs9nrm53r1penffmuex6ruqy8nxp7ms1h1")
      true

      iex> address_valid("clearly not valid")
      false

  """
  def address_valid?(address) do
    {_pre, checksum} = 
      address
      |> String.trim("xrb_")
      |> String.split_at(-8)

    try do
      computed_checksum =
        address
        |> address_to_public_without_trim()
        |> Tools.Base.compute_checksum!()

      attached_checksum = Tools.Base.decode!(checksum) |> reverse()

      computed_checksum == attached_checksum
    rescue
      _ -> false
    end
  end

  @doc """
  Converts a raiblocks address to a public key.
  """
  def address_to_public(address) do
    binary = address_to_public_without_trim(address)
    binary_part(binary, 0, byte_size(binary) - 5)
  end

  @doc """
  Same as `address_to_public` except leaves untrimmied 5 bytes on end of binary.
  """
  def address_to_public_without_trim(address) do
    binary =
      address
      |> String.trim("xrb_")
      |> Tools.Base.decode!()

    <<_drop::size(4), pub_key::binary>> = binary

    pub_key
  end

  @doc """
  Creates an address from the given *public key*. The address is encoded in
  base32 as defined in `RaiEx.Tools.Base` and appended with a checksum.

  ## Examples

      iex> create_address!(<<125, 169, 163, 231, 136, 75, 168, 59, 83, 105, 128, 71, 82, 149, 53, 87, 90, 35, 149, 51, 106, 243, 76, 13, 250, 28, 59, 128, 5, 181, 81, 116>>)
      "xrb_1zfbnhmrikxa9fbpm149cccmcott6gcm8tqmbi8zn93ui14ucndn93mtijeg"

      iex> create_address!("7DA9A3E7884BA83B53698047529535575A2395336AF34C0DFA1C3B8005B55174")
      "xrb_1zfbnhmrikxa9fbpm149cccmcott6gcm8tqmbi8zn93ui14ucndn93mtijeg"

  """
  def create_address!(pub_key) do
    # This allows both a binary input or hex string
    pub_key = if_string_hex_to_binary(pub_key)

    encoded_check =
      pub_key
      |> Tools.Base.compute_checksum!
      |> Tools.reverse()
      |> Tools.Base.encode!()

    encoded_address =
      pub_key
      |> pad_binary(4)
      |> Tools.Base.encode!

    "xrb_#{encoded_address <> encoded_check}"
  end

  @doc """
  Derives the public key from the private key.

  ## Examples

      iex> derive_public(<<84, 151, 51, 84, 136, 206, 7, 211, 66, 222, 10, 240, 159, 113, 36, 98, 93, 238, 29, 96, 95, 8, 33, 62, 53, 162, 139, 52, 75, 123, 38, 144>>)
      <<125, 169, 163, 231, 136, 75, 168, 59, 83, 105, 128, 71, 82, 149, 53, 87, 90, 35, 149, 51, 106, 243, 76, 13, 250, 28, 59, 128, 5, 181, 81, 116>>
  
      iex> derive_public("5497335488CE07D342DE0AF09F7124625DEE1D605F08213E35A28B344B7B2690")
      <<125, 169, 163, 231, 136, 75, 168, 59, 83, 105, 128, 71, 82, 149, 53, 87, 90, 35, 149, 51, 106, 243, 76, 13, 250, 28, 59, 128, 5, 181, 81, 116>>

  """
  def derive_public(priv_key) do
    # This allows both a binary input or hex string
    priv_key = if_string_hex_to_binary(priv_key)
    
    Ed25519.derive_public_key(priv_key)
  end

  @doc """
  Generates the public and private keys for a given *wallet*.

  ## Examples

      iex> seed_account("8208BD79655E7141DCFE792084AB6A8FDFFFB56F37CE30ADC4C2CC940E276A8B", 0)
      {pub, priv}

  """
  def seed_account(seed, nonce) do
    # This allows both a binary input or hex string
    seed = if_string_hex_to_binary(seed)

    priv = Blake2.hash2b(seed <> <<nonce::size(32)>>, 32)
    pub  = derive_public(priv)

    {priv, pub} 
  end



  def send_block(%Block{
    type: type,
    previous: previous,
    destination: destination,
    balance: balance,
    work: work,
    signature: signature
  }) do
      
  end

  def sign_block(%Block{
    type: type,
    previous: previous,
    destination: destination,
    balance: balance,
    work: work,
    signature: signature
  }, priv_key, pub_key \\ nil) do
    # Converts binaries if necessary
    [priv_key, pub_key, previous, destination, balance] =
      if_string_hex_to_binary([priv_key, pub_key, previous, destination, balance])

    hash = Blake2.hash2b(previous <> destination <> balance, 32)
    Ed25519.signature(hash, priv_key, pub_key)
  end

  # Converts a hex string to binary if necessary
  defp if_string_hex_to_binary([]), do: []
  defp if_string_hex_to_binary(binaries) when is_list(binaries) do
    [binary | rest] = binaries
    [if_string_hex_to_binary(binary) | if_string_hex_to_binary(rest)]
  end
  defp if_string_hex_to_binary(binary) do
    if String.valid?(binary), do: Base.decode16!(binary), else: binary
  end

  # Reverses a binary
  def reverse(binary) when is_binary(binary), do: do_reverse(binary, <<>>)
  defp do_reverse(<<>>, acc), do: acc
  defp do_reverse(<< x :: binary-size(1), bin :: binary >>, acc), do: do_reverse(bin, x <> acc)

  # Left pads some binary
  defp pad_binary(binary, bits) do
    <<0::size(bits), binary::bitstring>>
  end
end
