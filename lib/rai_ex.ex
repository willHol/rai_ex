defmodule RaiEx do
  @moduledoc """
  This module contains the definitions of all the RaiBlocks node RPC calls.
  """

  import HTTPoison
  use RPC

  alias HTTPoison.Response
  alias HTTPoison.Error

  @headers [{"Content-Type", "application/json"}]
  @options [recv_time: 5000, timeout: 10000]
  @default_url "http://localhost:7076"
  @wait_time 75
  @retry_count 3

  @doc """
  Used to connect to a different endpoint.
  """
  def connect(url \\ @default_url) do
    Application.put_env(:rai_ex, :url, parse_url(url))
  end

  @doc """
  Returns how many RAW is owned and how many have not yet been received by `account`.
  """
  rpc :account_balance do
    param "account", :address
  end

  @doc """
  Gets the number of blocks for a specific `account`.
  """
  rpc :account_block_count do
    param "account", :address
  end

  @doc """
  Returns frontier, open block, change representative block, balance,
  last modified timestamp from local database & block count for `account`.
  """
  rpc :account_info do
    param "account", :address
  end

  @doc """
  Creates a new account, insert next deterministic key in `wallet`.
  """
  rpc :account_create do
    param "wallet", :wallet
  end

  @doc """
  Get account number for the `public key`.
  """
  rpc :account_get do
    param "key", :string
  end

  @doc """
  Reports send/receive information for an `account`.
  """
  rpc :account_history do
    param "account", :address
    param "count", :integer
  end

  @doc """
  Lists all the accounts inside `wallet`.
  """
  rpc :account_list do
    param "wallet", :wallet
  end

  @doc """
  Moves accounts from `source` to `wallet`.

  # Node must have 'enable_control' set to 'true'
  """
  rpc :account_move do
    param "wallet", :wallet
    param "source", :address
    param "accounts", :address_list
  end

  @doc """
  Get the `public key` for `account`.
  """
  rpc :account_key do
    param "account", :address
  end

  @doc """
  Remove `account` from `wallet`.
  """
  rpc :account_remove do
    param "wallet", :wallet
    param "account", :address
  end

  @doc """
  Returns the representative for `account`.
  """
  rpc :account_representative do
    param "account", :address
  end

  @doc """
  Sets the representative for `account` in `wallet`.

  # Node must have 'enable_control' set to 'true'
  """
  rpc :account_representative_set do
    param "wallet", :wallet
    param "account", :address
    param "representative", :string
  end

  @doc """
  Returns the voting weight for `account`.
  """
  rpc :account_weight do
    param "account", :address
  end

  @doc """
  Returns how many RAW is owned and how many have not yet been received by accounts list.
  """
  rpc :accounts_balances do
    param "accounts", :address_list
  end

  @doc """
  Returns a list of pairs of account and block hash representing the head block for `accounts`.
  """
  rpc :accounts_frontiers do
    param "accounts", :address_list
  end

  @doc """
  Returns a list of block hashes which have not yet been received by these `accounts`.

  # Optional `threshold`, only returns hashes with amounts >= threshold.
  """
  rpc :accounts_pending do
    param "accounts", :address_list
    param "count", :integer
  end

  rpc :accounts_pending do
    param "accounts", :address_list
    param "count", :integer
    param "threshold", :number
  end

  @doc """
  Returns how many rai are in the public supply.
  """
  rpc :available_supply do
  end

  @doc """
  Retrieves a json representation of `block`.
  """
  rpc :block do
    param "hash", :hash
  end

  @doc """
  Retrieves a json representations of multiple `blocks`.
  """
  rpc :blocks do
    param "hashes", :hash_list
  end

  @doc """
  Retrieves a json representations of `blocks` with transaction `amount` & block `account`.
  """
  rpc :blocks_info do
    param "hashes", :hash_list
  end

  @doc """
  Returns the `account` containing the `block`.
  """
  rpc :block_account do
    param "hash", :hash
  end

  @doc """
  Reports the number of blocks in the ledger and unchecked synchronizing blocks.
  """
  rpc :block_count do
  end

  @doc """
  Reports the number of blocks in the ledger by type (send, receive, open, change).
  """
  rpc :block_count_type do
  end

  @doc """
  Initialize bootstrap to specific IP address and `port`.
  """
  rpc :bootstrap do
    param "address", :string
    param "port", :integer
  end

  @doc """
  Initialize multi-connection bootstrap to random peers.
  """
  rpc :bootstrap_any do
  end

  @doc """
  Returns a list of block hashes in the account chain starting at `block` up to `count`.
  """
  rpc :chain do
    param "block", :block
    param "count", :integer
  end

  @doc """
  Returns a list of pairs of delegator names given `account` a representative and its balance.
  """
  rpc :delegators do
    param "account", :address
  end

  @doc """
  Get number of delegators for a specific representative `account`.
  """
  rpc :delegators_count do
    param "account", :address
  end

  @doc """
  Derive deterministic keypair from `seed` based on `index`.
  """
  rpc :deterministic_key do
    param "seed", :string
    param "index", :integer
  end

  @doc """
  Returns a list of pairs of account and block hash representing the head block starting at account up to count.
  """
  rpc :frontiers do
    param "account", :address
    param "count", :integer
  end

  @doc """
  Reports the number of accounts in the ledger.
  """
  rpc :frontier_count do
  end

  @doc """
  Reports send/receive information for a chain of blocks.
  """
  rpc :history do
    param "hash", :hash
    param "count", :integer
  end

  @doc """
  Divide a raw amount down by the Mrai ratio.
  """
  rpc :mrai_from_raw do
    param "amount", :number
  end

  @doc """
  Multiply an Mrai amount by the Mrai ratio.
  """
  rpc :mrai_to_raw do
    param "amount", :number
  end

  @doc """
  Divide a raw amount down by the krai ratio.
  """
  rpc :krai_from_raw do
    param "amount", :number
  end

  @doc """
  Multiply an krai amount by the krai ratio.
  """
  rpc :krai_to_raw do
    param "amount", :number
  end

  @doc """
  Divide a raw amount down by the rai ratio.
  """
  rpc :rai_from_raw do
    param "amount", :number
  end

  @doc """
  Multiply an rai amount by the rai ratio.
  """
  rpc :rai_to_raw do
    param "amount", :number
  end

  @doc """
  Tells the node to send a keepalive packet to address:port.
  """
  rpc :keepalive do
    param "address", :string
    param "port", :integer
  end

  @doc """
  Generates an `adhoc random keypair`
  """
  rpc :key_create do
  end

  @doc """
  Derive public key and account number from `private key`.
  """
  rpc :key_expand do
    param "key", :string
  end

  @doc """
  Begin a new payment session. Searches wallet for an account that's
  marked as available and has a 0 balance. If one is found, the account
  number is returned and is marked as unavailable. If no account is found,
  a new account is created, placed in the wallet, and returned.
  """
  rpc :payment_begin do
    param "wallet", :wallet
  end

  @doc """
  Marks all accounts in wallet as available for being used as a payment session.
  """
  rpc :payment_init do
    param "wallet", :wallet
  end

  @doc """
  End a payment session. Marks the account as available for use in a payment session.
  """
  rpc :payment_end do
    param "account", :address
    param "wallet", :wallet
  end

  @doc """
  Wait for payment of 'amount' to arrive in 'account' or until 'timeout' milliseconds have elapsed.
  """
  rpc :payment_wait do
    param "account", :address
    param "amount", :number
    param "timeout", :number
  end

  @doc """
  Publish `block` to the network.
  """
  rpc :process do
    param "block", :any
  end

  @doc """
  Receive pending block for account in wallet
  
  enable_control must be set to true
  """
  rpc :receive do
    param "wallet", :wallet
    param "account", :address
    param "block", :block
  end

  @doc """
  Returns receive minimum for node.
  
  enable_control must be set to true
  """
  rpc :receive_minimum do
  end

  @doc """
  Set `amount` as new receive minimum for node until restart
  """
  rpc :receive_minimum_set do
    param "amount", :number
  end

  @doc """
  Returns a list of pairs of representative and its voting weight.
  """
  rpc :representatives do
  end

  @doc """
  Returns the default representative for `wallet`.
  """
  rpc :wallet_representative do
    param "wallet", :wallet
  end

  @doc """
  Sets the default representative for wallet.
  
  enable_control must be set to true
  """
  rpc :wallet_representative_set do
    param "wallet", :wallet
    param "representative", :string
  end

  @doc """
  Rebroadcast blocks starting at `hash` to the network.
  """
  rpc :republish do
    param "hash", :hash
  end

  @doc """
  Additionally rebroadcast source chain blocks for receive/open up to `sources` depth.
  """
  rpc :republish do
    param "hash", :hash
    param "sources", :integer
  end

  @doc """
  Tells the node to look for pending blocks for any account in `wallet`.
  """
  rpc :search_pending do
    param "wallet", :wallet
  end

  @doc """
  Tells the node to look for pending blocks for any account in all available wallets.
  """
  rpc :search_pending_all do
  end

  @doc """
  Send `amount` from `source` in `wallet` to destination
  """
  rpc :send do
    param "wallet", :wallet
    param "source", :address
    param "destination", :string
    param "amount", :number
  end

  @doc """
  enable_control must be set to true
  """
  rpc :stop do
  end

  @doc """
  Check whether account is a valid account number.
  """
  rpc :validate_account_number do
    param "account", :address
  end

  @doc """
  Returns a list of block hashes in the account chain ending at block up to count.
  """
  rpc :successors do
    param "block", :block
    param "count", :number
  end

  @doc """
  Retrieves node versions.
  """
  rpc :version do
  end

  @doc """
  Returns a list of pairs of peer IPv6:port and its node network version.
  """
  rpc :peers do
  end

  @doc """
  Returns a list of block hashes which have not yet been received by this account.
  """
  rpc :pending do
    param "account", :address
    param "count", :integer
  end

  @doc """
  Returns a list of pending block hashes with amount more or equal to threshold.
  """
  rpc :pending do
    param "account", :address
    param "count", :integer
    param "threshold", :number
  end

  @doc """
  Check whether block is pending by hash.
  """
  rpc :pending_exists do
    param "hash", :hash
  end

  @doc """
  Returns a list of pairs of unchecked synchronizing block hash and its json representation up to count.
  """
  rpc :unchecked do
    param "count", :integer
  end

  @doc """
  Clear unchecked synchronizing blocks.
  
  enable_control must be set to true
  """
  rpc :unchecked_clear do
  end

  @doc """
  Retrieves a json representation of unchecked synchronizing block by hash.
  """
  rpc :unchecked_get do
    param "hash", :hash
  end

  @doc """
  Retrieves unchecked database keys, blocks hashes & a json representations of unchecked pending blocks starting from key up to count.
  """
  rpc :unchecked_keys do
    param "key", :string
    param "count", :integer
  end

  @doc """
  Add an adhoc private key key to wallet.
  
  enable_control must be set to true
  """
  rpc :wallet_add do
    param "wallet", :wallet
    param "key", :string
  end

  @doc """
  Returns the sum of all accounts balances in wallet.
  """
  rpc :wallet_balance_total do
    param "wallet", :wallet
  end

  @doc """
  Returns how many rai is owned and how many have not yet been received by all accounts in .
  """
  rpc :wallet_balances do
    param "wallet", :wallet
  end

  @doc """
  Changes seed for wallet to seed.
  
  enable_control must be set to true
  """
  rpc :wallet_change_seed do
    param "wallet", :wallet
    param "seed", :string
  end

  @doc """
  Check whether wallet contains account.
  """
  rpc :wallet_contains do
    param "wallet", :wallet
    param "account", :address
  end

  @doc """
  Creates a new random wallet id.
  
  enable_control must be set to true
  """
  rpc :wallet_create do
  end

  @doc """
  Destroys wallet and all contained accounts.
  
  enable_control must be set to true
  """
  rpc :wallet_destroy do
    param "wallet", :wallet
  end

  @doc """
  Return a json representation of wallet.
  """
  rpc :wallet_export do
    param "wallet", :wallet
  end

  @doc """
  Returns a list of pairs of account and block hash representing the head block starting
  for accounts from wallet.
  """
  rpc :wallet_frontiers do
    param "wallet", :wallet
  end

  @doc """
  Returns a list of block hashes which have not yet been received by accounts in this wallet.
  
  enable_control must be set to true
  """
  rpc :wallet_pending do
    param "wallet", :wallet
    param "count", :integer
  end

  @doc """
  Returns a list of pending block hashes with amount more or equal to threshold.
  
  enable_control must be set to true
  """
  rpc :wallet_pending do
    param "wallet", :wallet
    param "count", :integer
    param "threshold", :number
  end

  @doc """
  Rebroadcast blocks for accounts from wallet starting at frontier down to count to the network.
  
  enable_control must be set to true
  """
  rpc :wallet_republish do
    param "wallet", :wallet
    param "count", :integer
  end

  @doc """
  Returns a list of pairs of account and work from wallet.
  
  enable_control must be set to true
  """
  rpc :wallet_work_get do
    param "wallet", :wallet
  end

  @doc """
  Changes the password for wallet to password.
  
  enable_control must be set to true
  """
  rpc :password_change do
    param "wallet", :wallet
    param "password", :string
  end

  @doc """
  Enters the password in to wallet.
  """
  rpc :password_enter do
    param "wallet", :wallet
    param "password", :string
  end

  @doc """
  Checks whether the password entered for wallet is valid.
  """
  rpc :password_valid do
    param "wallet", :wallet
  end

  @doc """
  Stop generating work for block.
  
  enable_control must be set to true
  """
  rpc :work_cancel do
    param "hash", :hash
  end

  @doc """
  Generates work for block
  
  enable_control must be set to true
  """
  rpc :work_generate do
    param "hash", :hash, timeout: 30000
  end

  @doc """
  Retrieves work for account in wallet.
  
  enable_control must be set to true
  """
  rpc :work_get do
    param "wallet", :wallet
    param "account", :address
  end

  @doc """
  Set work for account in wallet.
  
  enable_control must be set to true
  """
  rpc :work_set do
    param "wallet", :wallet
    param "account", :address
    param "work", :string
  end

  @doc """
  Add specific IP address and port as work peer for node until restart.
  
  enable_control must be set to true
  """
  rpc :work_peer_add do
    param "address", :string
    param "port", :integer
  end

  @doc """
  Retrieves work peers.
  
  enable_control must be set to true
  """
  rpc :work_peers do
  end

  @doc """
  Clear work peers node list until restart.
  
  enable_control must be set to true
  """
  rpc :work_peers_clear do
  end

  @doc """
  Check whether work is valid for block.
  """
  rpc :work_validate do
    param "work", :string
    param "hash", :hash
  end

  # Parses a URL into its fully qualified form
  defp parse_url(url) do
    case String.splitter(url, ["://", ":"]) |> Enum.take(3) do
      ["http", "localhost", port] -> "http://#{local_host()}:#{port}"
      ["http", host, port] -> "http://#{host}:#{port}"
      ["http", host] -> "http://#{host}:#{default_port()}"
      [host, port] -> "http://#{host}:#{port}"
      [host] -> "http://#{host}:#{default_port()}"
    end
  end

  defp default_port, do: Application.get_env(:rai_ex, :default_port, 7075)

  defp local_host, do: Application.get_env(:rai_ex, :localhost, "127.0.0.1")

  defp get_url, do: Application.get_env(:rai_ex, :url, @default_url)

  @doc """
  Posts some json to the RaiBlocks rpc. If the POST is unsuccessful,
  it is re-sent `@retry_count` many times with a delay of `@wait_time`
  between retries. Callback implementation for `RaiEx.RPC`.

  ## Examples

      iex> post_json_rpc(%{"action" => "wallet_create"})
      {:ok, %{"wallet" => "0000000000000000"}}

      iex> post_json_rpc(%{"action" => "timeout"})
      {:error, reason}

  """
  def post_json_rpc(json, opts \\ [], tries \\ @retry_count, prev_reason \\ {:error, :unknown})
  def post_json_rpc(_json, _opts, 0, reason), do: {:error, reason}
  def post_json_rpc(json, opts, tries, _prev_reason) do
    comb_opts = Keyword.merge(@options, opts)

    with {:ok, %Response{status_code: 200, body: body}} <- request(:post, get_url(), json, @headers, comb_opts),
         {:ok, map} <- Poison.decode(body)
         do
          {:ok, map}
         else
          {:error, %Error{reason: reason}} ->
            :timer.sleep(@wait_time)
            post_json_rpc(json, opts, tries - 1, reason)
         end
    end
end
