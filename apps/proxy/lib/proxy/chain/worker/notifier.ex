defmodule Proxy.Chain.Worker.Notifier do
  @moduledoc """
  Internal notification helper for chain workers.
  All notifications to event handlers/other services have to be sent from here.
  """

  alias Proxy.Chain.Worker.State

  @doc """
  Send notification about chain to `notify_pid`.
  If no `notify_pid` config exist into state - `:ok` will be returned
  """
  @spec notify(Proxy.Chain.Worker.State.t(), binary | atom, term()) :: :ok
  def notify(state, event, data \\ %{})

  def notify(%State{notify_pid: nil}, _, _), do: :ok

  def notify(%State{id: id, notify_pid: pid}, event, data),
    do: send(pid, %{id: id, event: event, data: data})

  @doc """
  Send notification to oracles service about adding new relayer.
  If no required deployment information exist - error will be returned
  """
  @spec notify_oracles(Proxy.Chain.Worker.State.t()) :: {:ok, term()} | {:error, term()}
  def notify_oracles(%State{
        deploy_step: %{"ilks" => ilks, "omniaFromAddr" => from},
        chain_details: %{rpc_url: url},
        deploy_data: data
      })
      when is_map(data) do
    pairs =
      ilks
      |> Enum.filter(fn {_symbol, conf} -> get_in(conf, ["pip", "type"]) == "median" end)
      |> Enum.map(fn {symbol, _} -> {symbol, Map.get(data, "VAL_#{symbol}")} end)
      |> Enum.reject(&is_nil/1)

    Proxy.Oracles.Api.new_relayer(url, from, pairs)
  end

  def notify_oracles(_), do: {:error, "failed to get all required details"}
end
