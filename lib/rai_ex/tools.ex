defmodule RaiEx.Tools do
	@moduledoc """
	This module is provides convenience functions for
	working with payments.
	"""

  alias RaiEx.Tools

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
  Creates a new adhod wallet.
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
    {check, sum} = 
      address
      |> String.trim("xrb_")
      |> String.split_at(-8)

    try do
      <<_drop::size(4), keep::binary>> = Tools.Base.decode!(check)

      computed_checksum = Tools.Base.compute_checksum!(keep)
      attached_checksum =Tools.Base.decode!(sum) |> reverse()

      computed_checksum == attached_checksum
    rescue
      _ -> false
    end
  end

  @doc """
  Creates an address from the given *public key*. The address is encoded in
  base32 as defined in `RaiEx.Tools.Base` and appended with a checksum.
  """
  def create_address!(public_key) do
    encoded_check =
      public_key
      |> Tools.Base.compute_checksum!
      |> Tools.reverse()
      |> Tools.Base.encode!()

    encoded_address =
      public_key
      |> pad_binary(4)
      |> Tools.Base.encode!

    "xrb_#{encoded_address <> encoded_check}"
  end

  def derive_public(private_key) do
    Ed25519.derive_public_key(private_key)
  end

  @doc """
  Generates the public and private keys for a given *wallet
  """
  def seed_account(seed, nonce) do
    Blake2.hash2b(seed <> <<nonce::size(32)>> , 32)
  end

  # Reverses a binary
  def reverse(binary) when is_binary(binary), do: do_reverse(binary, <<>>)
  defp do_reverse(<<>>, acc), do: acc
  defp do_reverse(<< x :: binary-size(1), bin :: binary >>, acc), do: do_reverse(bin, x <> acc)

  #
  def stretch_binary(binary, output_length) do
    pad_binary(binary, 32 - bit_size(binary))
  end
  # Left pads some binary
  defp pad_binary(binary, bits) do
    <<0::size(bits), binary::bitstring>>
  end
end
