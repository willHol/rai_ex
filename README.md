# RaiEx

RaiEx is an *Elixir client* for managing a **RaiBlocks** node, here is an example:

```elixir

# Tell RaiEx where to connect to, default is: 'http://127.0.0.1:7076'
:ok = RaiEx.connect("http://192.165.0.78:4000")

account = "xrb_3t6k35gi95xu6tergt6p69ck76ogmitsa8mnijtpxm9fkcm736xtoncuohr3"

# RPC mappings
{:ok, %{"balance" => balance, "frontier" => frontier}} = RaiEx.account_info(account)
{:ok, %{"key" => key}} = RaiEx.account_key(account)

# Derive the first account from the wallet seed
{priv, pub} = seed_account("8208BD79655E7141DCFE792084AB6A8FDFFFB56F37CE30ADC4C2CC940E276A8B", 0)

# Derives an "xrb_" address
address = Tools.create_account!(pub)

# Get the previous block hash
{:ok, %{"frontier" => block_hash}} = RaiEx.account_info(address)

block = %Block{
  previous: block_hash,
  destination: "xrb_1aewtdjz8knar65gmu6xo5tmp7ijrur1fgtetua3mxqujh5z9m1r77fsrpqw",
  balance: 0
}

# Signs and broadcasts the block to the network
block |> Block.sign(priv, pub) |> Block.send()

```

To get started read the [online documentation](https://hexdocs.pm/rai_ex/).

## Installation

Add the following to your `mix.exs`:

```elixir
def deps do
  [
    {:rai_ex, "~> 0.2.0"}
  ]
end
```
