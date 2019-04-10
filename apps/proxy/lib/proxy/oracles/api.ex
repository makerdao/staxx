defmodule Proxy.Oracles.Api do
  @moduledoc """
  Module will handle communication with Oracles service
  """

  use HTTPoison.Base

  require Logger

  # Post request rimeout
  @timeout 2000

  @doc false
  def process_response_body(""), do: %{}

  def process_response_body(body) do
    case Jason.decode(body, keys: :strings) do
      {:ok, parsed} ->
        parsed

      {:error, err} ->
        Logger.error("Error parsing response #{inspect(body)} with error: #{inspect(err)}")
        body
    end
  end

  @doc """
  New relayer request. 
  Need to be done after new chain deployment finished
  """
  @spec new_relayer(binary, binary, [{binary, binary}]) :: {:ok, term()} | {:error, term()}
  def new_relayer(rpc_url, from, pairs \\ []) do
    case send?() do
      false ->
        {:ok, %{}}

      true ->
        req =
          %{
            "ethereum" => %{
              "network" => rpc_url,
              "infuraKey" => "7e7589fbfb8e4237b6ad945825a1d791",
              "from" => from,
              "keystore" => "/home/nkunkel/keys/",
              "password" => "/home/nkunkel/keys/unlock-key"
            },
            "pairs" => gen_pairs(%{}, pairs),
            "options" => %{
              "interval" => 60,
              "msgSpread" => 0.5,
              "msgExpiration" => 180,
              "oracleSpread" => 1,
              "oracleExpiration" => 3600,
              "verbose" => true,
              "relayer" => true
            }
          }
          |> Jason.encode!()

        Logger.debug("Calling oracles service with data: #{req}")

        "#{url()}v1/relayer/new/"
        |> post(req, [{"Content-Type", "application/json"}], recv_timeout: @timeout)
        |> fetch_result()
    end
  end

  @doc """
  Kill relayer
  """
  @spec remove_relayer() :: {:ok, term()} | {:error, term()}
  def remove_relayer() do
    case send?() do
      false ->
        {:ok, %{}}

      true ->
        "#{url()}v1/relayer/kill/"
        |> post("", [{"Content-Type", "application/json"}], recv_timeout: @timeout)
        |> fetch_result()
    end
  end

  @doc """
  Send notification to oracles service about adding new relayer.
  If no required deployment information exist - error will be returned
  """
  @spec notify_new_chain(Proxy.Chain.Storage.Record.t()) :: {:ok, term()} | {:error, term()}
  def notify_new_chain(%Proxy.Chain.Storage.Record{
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

    new_relayer(url, from, pairs)
  end

  def notify_new_chain(_), do: {:error, "failed to get all required details"}

  # Service URL
  defp url(), do: Application.get_env(:proxy, :oracles_service_url)

  # Combine pairs for oracles
  defp gen_pairs(res, []), do: res

  defp gen_pairs(res, [{symbol, address} | rest]) do
    res
    |> Map.put("#{symbol}USD", %{"decimals" => 18, "oracle" => address})
    |> gen_pairs(rest)
  end

  # Making decision on what is really right 
  # Note. It's 42 ^)
  defp fetch_result({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    Logger.debug("Oracles response #{inspect(body)}")
    {:ok, body}
  end

  defp fetch_result(res) do
    Logger.warn("Oracles error: #{inspect(res)}")
    {:error, "Wrong response form oracles service"}
  end

  # Check if oracles service should be called
  defp send?(), do: Application.get_env(:proxy, :call_oracles, false)
end
