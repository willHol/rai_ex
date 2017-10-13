defmodule RaiEx.Block do
  @doc """
  The block struct.
  """

  defstruct [
    type: "send",
    previous: nil,
    desination: nil,
    balance: 0,
    work: nil,
    signature: nil
  ]
end