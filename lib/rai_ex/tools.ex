defmodule RaiEx.Tools do
	@moduledoc """
	This module is provides convenience functions for
	working with payments.
	"""

  alias RaiEx.Tools.Base

	@delay 200

	def seed do
		<< int :: size(64) >> = :crypto.strong_rand_bytes(8)
		int
	end

	def change_password(wallet, current_pwd, password) do
		with {:ok, %{"valid" => "1"}} <- RaiEx.password_enter(wallet, current_pwd),
			 	 {:ok, %{"changed" => "1"}} <- RaiEx.password_change(wallet, password)
			 	 do {:ok, wallet} else {_, reason} -> {:error, reason} end
	end

	def wallet_create_encrypted(password) do
		with {:ok, %{"wallet" => wallet}} <- RaiEx.wallet_create,
				 _ <- :timer.sleep(@delay),
				 {:ok, ^wallet} <- change_password(wallet, "", password)
			   do {:ok, wallet} else {_, reason} -> {:error, reason} end
	end

	def wallet_add_adhoc(wallet) do
		with {:ok, %{"private" => priv, "public" => pub, "account" => acc}} <- RaiEx.key_create,
			   {:ok, %{"account" => ^acc}} <- RaiEx.wallet_add(wallet, priv)
			   do {:ok, %{"private" => priv, "public" => pub, "account" => acc}} else {_, reason} -> {:error, reason} end
	end

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

  def lock_wallet(wallet) do
    case RaiEx.password_enter(wallet, "") do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  def address_valid?(address) do
    {check, sum} = 
      address
      |> String.trim("xrb_")
      |> String.split_at(-8)

    try do
      <<_drop::size(4), keep::binary>> = Base.decode!(check)
      hash = Blake2.hash2b(keep, 5)
      cmp = Base.decode!(sum) |> reverse
      
      hash == cmp
    rescue
      _ -> false
    end
  
  end

  defp reverse(binary) when is_binary(binary), do: do_reverse(binary, <<>>)
  defp do_reverse(<<>>, acc), do: acc
  defp do_reverse(<< x :: binary-size(1), bin :: binary >>, acc), do: do_reverse(bin, x <> acc)
end
