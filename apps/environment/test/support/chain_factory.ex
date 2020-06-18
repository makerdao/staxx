defmodule Staxx.Environment.ChainFactory do
  use ExMachina

  alias Staxx.Environment
  alias Staxx.Docker.Container

  def chain_valid_factory do
    %{
      Environment.testchain_key() => %{
        "config" => %{
          "type" => "geth",
          "accounts" => 1,
          "block_mine_time" => 0,
          "clean_on_stop" => false,
          "snapshot_id" => nil,
          "deploy_tag" => "",
          "deploy_step_id" => 0
        },
        "deps" => []
      }
    }
  end

  def extension_valid_factory do
    %{
      "test" => %{
        "config" => %{},
        "deps" => [Environment.testchain_key()]
      }
    }
  end

  def not_allowed_extension_factory do
    %{
      "some_other" => %{
        "config" => %{},
        "deps" => [Environment.testchain_key()]
      }
    }
  end

  def container_valid_factory do
    %Container{
      # see /priv/test/extension/test/extension.json
      image: "some/container",
      ports: [3000]
    }
  end

  def container_invalid_factory do
    %Container{
      # see /priv/test/extension/test/extension.json
      image: "some/other-container"
    }
  end
end
