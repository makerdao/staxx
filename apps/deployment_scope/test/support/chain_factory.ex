defmodule Staxx.DeploymentScope.ChainFactory do
  use ExMachina

  def chain_valid_factory do
    %{
      "testchain" => %{
        "config" => %{
          "type" => "geth",
          "accounts" => 2,
          "block_mine_time" => 0,
          "clean_on_stop" => false,
          "snapshot_id" => nil,
          "step_id" => 0
        },
        "deps" => []
      }
    }
  end

  def helloworld_valid_factory do
    %{
      "helloworld" => %{
        "config" => %{},
        "deps" => ["testchain"]
      }
    }
  end

  def not_allowed_stack_factory do
    %{
      "some_other" => %{
        "config" => %{},
        "deps" => ["testchain"]
      }
    }
  end
end
