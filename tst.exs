RaiEx.connect "localhost"

# Create a wallet for user
{:ok, %{"wallet" => wallet}} = RaiEx.wallet_create

# # Generate deterministic seed for wallet - 256 bits
<< int :: size(16) >> = :crypto.strong_rand_bytes(8)

# # Set the seed
# {:ok, %{"success" => _}} = RaiEx.wallet_change_seed(wallet, seed)

# Generate random pub/priv pair
{:ok, %{"private" => priv, "public" => pub, "account" => acc}} = RaiEx.key_create

# Insert the key into users wallet
{:ok, %{"account" => acc}} = RaiEx.wallet_add(wallet, priv)


