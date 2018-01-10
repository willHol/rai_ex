defmodule RaiEx.Tools.Validator do
  @moduledoc """
  Provides functionality for run-time validation of rpc types.
  """

  @type_checkers %{
    :string => {Kernel, :is_binary},
    :number => {Decimal, :decimal?},
    :integer => {Kernel, :is_integer},
    :list => {Kernel, :is_list},
    :wallet => {__MODULE__, :is_hash},
    :hash => {__MODULE__, :is_hash},
    :hash_list => {__MODULE__, :is_hash_list},
    :block => {__MODULE__, :is_hash},
    :address => {__MODULE__, :is_address},
    :address_list => {__MODULE__, :is_address_list},
    :boolean => {Kernel, :is_boolean},
    :any => {__MODULE__, :any}
  }

  @doc """
  Validates the type types used by `RaiEx.RPC`. Raises `ArgumentError`
  if the types fail to validate.

  ## Examples

      iex> validate_types(["account" => :string, "count" => :integer], ["account" => "xrb_34bmpi65zr967cdzy4uy4twu7mqs9nrm53r1penffmuex6ruqy8nxp7ms1h1, "count" => 5])
      :ok

      iex> validate_types(["account" => :string, "count" => :integer], ["account" => "xrb_34bmpi65zr967cdzy4uy4twu7mqs9nrm53r1penffmuex6ruqy8nxp7ms1h1, "count" => "10"])
      ** (Elixir.ArgumentError)

  """
  def validate_types!(should_be, is) do
    should_be = Enum.into(should_be, %{})
    Enum.each(should_be, fn {param, type} ->
      {mod, fun} = @type_checkers[type]
      arg = is[String.to_atom(param)]

      unless apply(mod, fun, [arg]) do
        raise ArgumentError, message: """
        #{param} is not of the correct type, should be type: #{type}
        """
      end
    end)

    :ok
  end

  @doc false
  def is_hash(wallet) do
    is_binary(wallet) and String.length(wallet) == 64 and Regex.match?(~r/^[0-9A-F]+$/, wallet)
  end

  @doc false
  def is_address(addr) do
    is_binary(addr) and
    String.length(addr) == 64 and
    Regex.match?(~r/^[0-9a-z_]+$/, addr) and
    String.starts_with?(addr, "xrb_")
  end

  @doc false
  def is_address_list(addr_list) do
    if is_list(addr_list), do: addr_list |> Enum.all?(&(is_address(&1))), else: false
  end
 
  @doc false
  def is_hash_list(hash_list) do
    if is_list(hash_list), do: hash_list |> Enum.all?(&(is_hash(&1))), else: false
  end

  @doc false
  def any(_), do: true
end
