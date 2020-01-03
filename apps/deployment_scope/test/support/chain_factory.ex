defmodule Staxx.DeploymentScope.ChainFactory do
  use ExMachina

  alias Staxx.Docker.Container

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

  def stack_valid_factory do
    %{
      "test" => %{
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

  def container_valid_factory do
    %Container{
      # see /priv/test/stack/test/stack.json
      image: "some/container",
      ports: [3000]
    }
  end

  def container_invalid_factory do
    %Container{
      # see /priv/test/stack/test/stack.json
      image: "some/other-container"
    }
  end
end
