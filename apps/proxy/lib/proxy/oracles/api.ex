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

    url()
    |> post(req, [{"Content-Type", "application/json"}], recv_timeout: @timeout)
    |> fetch_result()
  end

  # Service URL
  defp url(), do: Application.get_env(:proxy, :oracles_service_url)

  # Combine pairs for oracles
  defp gen_pairs(res, []), do: res

  defp gen_pairs(res, [{symbol, address} | rest]) do
    res
    |> Map.put(symbol, %{"decimals" => 18, "oracle" => address})
    |> gen_pairs(rest)
  end

  # Making decision on what is really right 
  # Note. It's 42 ^)
  defp fetch_result({:ok, %HTTPoison.Response{status_code: 200, body: body}}),
    do: {:ok, body}

  defp fetch_result(_res),
    do: {:error, "Wrong response form oracles service"}
end
