defmodule RaiEx.Tools do
	@moduledoc """
	This module is provides convenience functions for
	working with payments.
	"""

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
end