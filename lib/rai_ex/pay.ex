defmodule RaiEx.Pay do
	@moduledoc """
	This module is provides convenience functions for
	working with payments.
	"""

	def seed do
		<< int :: size(64) >> = :crypto.strong_rand_bytes(8)
		int
	end
end