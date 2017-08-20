RaiEx.connect "localhost:7075"

# Create a wallet for user
{:ok, %{"wallet" => wallet}} = RaiEx.wallet_create

# # Generate deterministic seed for wallet - 256 bits
# seed = :crypto.strong_rand_bytes(7) |> Base.encode16

# # Set the seed
# {:ok, %{"success" => _}} = RaiEx.wallet_change_seed(wallet, seed)

# Generate random pub/priv pair
{:ok, %{"private" => priv, "public" => pub, "account" => acc}} = RaiEx.key_create

# Insert the key into users wallet
{:ok, %{"account" => acc}} = RaiEx.wallet_add(wallet, priv)


