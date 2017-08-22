defmodule RaiEx.Pay do
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
		with {:ok, %{"valid" => "1"}} <- RaiEx.password_enter(wallet, ""),
			 	 {:ok, %{"changed" => "1"}} <- RaiEx.password_change(wallet, password),
			 	 do: {:ok, wallet}
	end

	def wallet_create_encrypted(password) do
		{:ok, %{"wallet" => wallet}} = RaiEx.wallet_create

		# Delay so the wallet is registered
		:timer.sleep(@delay)
			   
		with {:ok, ^wallet} <- change_password(wallet, password, password),
			   do: {:ok, wallet}
	end

	def wallet_add_adhoc(wallet) do
		with {:ok, %{"private" => priv, "public" => pub, "account" => acc}} <- RaiEx.key_create,
			   {:ok, %{"account" => ^acc}} <- RaiEx.wallet_add(wallet, priv),
			   do: {:ok, acc}
	end
end