defmodule WebApi.Utils do
  @moduledoc """
  Set of helper utils for chains/stacks
  """

  @doc """
  Convert payload (from POST) to valid chain config
  """
  @spec chain_config_from_payload(map) :: map
  def chain_config_from_payload(payload) when is_map(payload) do
    %{
      type: String.to_atom(Map.get(payload, "type", "ganache")),
      # id: Map.get(payload, "id"),
      # http_port: Map.get(payload, "http_port"),
      # ws_port: Map.get(payload, "ws_port"),
      # db_path: Map.get(payload, "db_path", ""),
      network_id: Map.get(payload, "network_id", 999),
      accounts: Map.get(payload, "accounts", 1),
      block_mine_time: Map.get(payload, "block_mine_time", 0),
      clean_on_stop: Map.get(payload, "clean_on_stop", false),
      description: Map.get(payload, "description", ""),
      snapshot_id: Map.get(payload, "snapshot_id"),
      deploy_tag: Map.get(payload, "deploy_tag"),
      step_id: Map.get(payload, "step_id", 0)
    }
  end
end
