defmodule RaiEx.BlockTest do
  use ExUnit.Case, async: true
  alias RaiEx.{Block, Tools}

  @seed "9F1D53E732E48F25F94711D5B22086778278624F715D9B2BEC8FB81134E7C904"

  describe "Block.sign/3 " do
    setup_all context do
      {priv, pub} = Tools.seed_account!(@seed, 0)
      account = Tools.create_account!(pub)

      # Passed to all tests
      {account, priv, pub}
    end

    test "correctly signs a send block", {account, priv, pub} do
      
    end
  end
end