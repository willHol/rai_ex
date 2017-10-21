defmodule RaiEx.BlockTest do
  use ExUnit.Case
  alias RaiEx.{Block, Tools}

  @seed "9F1D53E732E48F25F94711D5B22086778278624F715D9B2BEC8FB81134E7C904"
  
  @valid_send %{
    "balance" => "00000000000000000000000000000000",
    "destination" => "xrb_1aewtdjz8knar65gmu6xo5tmp7ijrur1fgtetua3mxqujh5z9m1r77fsrpqw",
    "previous" => "0FE7DF28D6CE577C6B38ACCAE6965B64DB406FF6DB0E3BF642B93E08EFBC8159",
    "signature" => "C8271FB970997DA285A746D1F62D7CE475DF7B6B35B1B30917B0844FF0B84B0ACBD9B2389D09827B5A51A8D700309544CDD2832D8CAB83A0590BA562C1197D0B",
    "type" => "send",
    "work" => "804ec4df247a987d",
    # non-standard, just for tests
    "hash" => "8F23E5790F995C38D4CC68E85932FA92025813713DEFE8D8E82368272F11C072"
  }

  @valid_recv %{
    "previous" => "6483B198E6CEF20727E0601D217E5E12598355F9C194B4CF9F75BE347FFCE4F9",
    "signature" => "6F700603E21105949A68E30FC3818B9E03B81D788983526ACFF457F67945C177ACE02B4DECCB1ED73FC1B10E02CACC2FA78A5535EA5232708C3E360C22F17305",
    "source" => "193ADF01F896E9955614F275738FCA63E684D3DE5FEB01398C55CD240D9210AB",
    "type" => "receive",
    "work" => "39bb3a33be963d66",
    # non-standard, just for tests
    "hash" => "5FA957F257DD62A4582A50E20206214D06F9E26167A11D76E60C392EC5695360"
  }

  @valid_open %{
    "account" => "xrb_34bmpi65zr967cdzy4uy4twu7mqs9nrm53r1penffmuex6ruqy8nxp7ms1h1",
    "representative" => "xrb_3arg3asgtigae3xckabaaewkx3bzsh7nwz7jkmjos79ihyaxwphhm6qgjps4",
    "signature" => "3311DF8325D87D4C528541F6D572CDA1D93605A61FD5D50DA2102EC8B456DCC72D72D3371FE166BD7A3074C284C4AFCA8F0A934B74462126D1BBDB0C5BCF3408",
    "source" => "FBC27450F270743B26630E7C8730B301105D4D26997372D94680360E99702825",
    "type" => "open",
    "work" => "e8907bfce904035a",
    # non-standard, just for tests
    "hash" => "1653FC490D5AE8786F659D646D49639F0DE13DCC98470D6FA3234D175B85526F"
  }

  setup _context do
    {priv, pub} = Tools.seed_account!(@seed, 0)
    account = Tools.create_account!(pub)

    # Passed to all tests
    {:ok, %{account: account, priv: priv, pub: pub}}
  end

  describe "Block.sign/3 " do
    test "signs a send block", %{priv: priv, pub: pub} do
      block =
        %Block{
          type: "send",
          previous: @valid_send["previous"],
          destination: @valid_send["destination"],
          balance: 0
        }
        |> Block.sign(priv, pub)

      assert block.hash === @valid_send["hash"]
      assert block.signature === @valid_send["signature"]
    end

    test "signs a receive block", %{priv: priv, pub: pub} do
      block =
        %Block{
          type: "receive",
          previous: @valid_recv["previous"],
          source: @valid_recv["source"],
        }
        |> Block.sign(priv, pub)

      assert block.hash === @valid_recv["hash"]
      assert block.signature === @valid_recv["signature"]
    end

    test "signs an open block", %{priv: priv, pub: pub} do
      block =
        %Block{
          type: "open",
          account: @valid_open["account"],
          representative: @valid_open["representative"],
          source: @valid_open["source"],
        }
        |> Block.sign(priv, pub)

      assert block.hash === @valid_open["hash"]
      assert block.signature === @valid_open["signature"]
    end
  end

  describe "Block.process/1 " do
    import TestHelper

    skip_offline()

    test "processes a send block and then processes a receive block", %{account: account, priv: priv, pub: pub} do
      {:ok, %{"frontier" => frontier}} = RaiEx.account_info(account)

      block =
        %Block{
          type: "send",
          previous: frontier,
          destination: account,
          balance: 0
        }
        |> Block.sign(priv, pub)
        |> Block.process()

      assert block.state === :sent

      # Give some time for the node to validate
      :timer.sleep(200)

      # Check if the block has been included
      {:ok, %{"frontier" => frontier}} = RaiEx.account_info(account)

      assert frontier === block.hash

      block =
        %Block{
          type: "receive",
          previous: frontier,
          source: frontier,
        }
        |> Block.sign(priv, pub)
        |> Block.process()

      assert block.state === :sent

      # Give some time for the node to validate
      :timer.sleep(200)

      # Check if the block has been included
      {:ok, %{"frontier" => frontier}} = RaiEx.account_info(account)

      assert frontier === block.hash
    end

    skip_offline()

    test "processes an open block", %{priv: priv, pub: pub} do
      block =
        %Block{
          type: "open",
          account: @valid_open["account"],
          representative: @valid_open["representative"],
          source: @valid_open["source"],
        }
        |> Block.sign(priv, pub)
        |> Block.process()

      assert block.state === :sent
    end
  end
end