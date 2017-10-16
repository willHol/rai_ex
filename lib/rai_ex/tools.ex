defmodule RaiEx.Tools do
  @moduledoc """
  This module provides convenience functions for working with a RaiBlocks node.
  """

  import RaiEx.Helpers

  alias RaiEx.Tools

  @delay 200

  @doc """
  Generates a wallet seed.
  """
  def seed do
    :crypto.strong_rand_bytes(32)
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
        |> address_to_public_without_trim!()
        |> hash_checksum!()

      attached_checksum = Tools.Base32.decode!(checksum) |> reverse()

      computed_checksum == attached_checksum
    rescue
      _ -> false
    end
  end

  @doc """
  Converts a raiblocks address to a public key.
  """
  def address_to_public!(address) do
    binary = address_to_public_without_trim!(address)
    binary_part(binary, 0, byte_size(binary) - 5)
  end

  @doc """
  Same as `RaiEx.Tools.address_to_public!` except leaves untrimmied 5 bytes at end of binary.
  """
  def address_to_public_without_trim!(address) do
    binary =
      address
      |> String.trim("xrb_")
      |> Tools.Base32.decode!()

    <<_drop::size(4), pub_key::binary>> = binary

    pub_key
  end

  @doc """
  Creates an address from the given *public key*. The address is encoded in
  base32 as defined in `RaiEx.Tools.Base32` and appended with a checksum.

  ## Examples

      iex> create_account!(<<125, 169, 163, 231, 136, 75, 168, 59, 83, 105, 128, 71, 82, 149, 53, 87, 90, 35, 149, 51, 106, 243, 76, 13, 250, 28, 59, 128, 5, 181, 81, 116>>)
      "xrb_1zfbnhmrikxa9fbpm149cccmcott6gcm8tqmbi8zn93ui14ucndn93mtijeg"

      iex> create_address!("7DA9A3E7884BA83B53698047529535575A2395336AF34C0DFA1C3B8005B55174")
      "xrb_1zfbnhmrikxa9fbpm149cccmcott6gcm8tqmbi8zn93ui14ucndn93mtijeg"

  """
  def create_account!(pub_key) do
    # This allows both a binary input or hex string
    pub_key = if_string_hex_to_binary(pub_key)

    encoded_check =
      pub_key
      |> hash_checksum!
      |> reverse()
      |> Tools.Base32.encode!()

    encoded_address =
      pub_key
      |> pad_binary(4)
      |> Tools.Base32.encode!

    "xrb_#{encoded_address <> encoded_check}"
  end

  @doc """
  Derives the public key from the private key.

  ## Examples

      iex> derive_public!(<<84, 151, 51, 84, 136, 206, 7, 211, 66, 222, 10, 240, 159, 113, 36, 98, 93, 238, 29, 96, 95, 8, 33, 62, 53, 162, 139, 52, 75, 123, 38, 144>>)
      <<125, 169, 163, 231, 136, 75, 168, 59, 83, 105, 128, 71, 82, 149, 53, 87, 90, 35, 149, 51, 106, 243, 76, 13, 250, 28, 59, 128, 5, 181, 81, 116>>
  
      iex> derive_public!("5497335488CE07D342DE0AF09F7124625DEE1D605F08213E35A28B344B7B2690")
      <<125, 169, 163, 231, 136, 75, 168, 59, 83, 105, 128, 71, 82, 149, 53, 87, 90, 35, 149, 51, 106, 243, 76, 13, 250, 28, 59, 128, 5, 181, 81, 116>>

  """
  def derive_public!(priv_key) do
    # This allows both a binary input or hex string
    priv_key = if_string_hex_to_binary(priv_key)
    
    Ed25519.derive_public_key(priv_key)
  end

  @doc """
  Generates the public and private keys for a given *wallet*.

  ## Examples

      iex> seed_account!("8208BD79655E7141DCFE792084AB6A8FDFFFB56F37CE30ADC4C2CC940E276A8B", 0)
      {pub, priv}

  """
  def seed_account!(seed, nonce) do
    # This allows both a binary input or hex string
    seed = if_string_hex_to_binary(seed)

    priv = Blake2.hash2b(seed <> <<nonce::size(32)>>, 32)
    pub  = derive_public!(priv)

    {priv, pub} 
  end

  defp hash_checksum!(check) do
    Blake2.hash2b(check, 5)
  end
end
