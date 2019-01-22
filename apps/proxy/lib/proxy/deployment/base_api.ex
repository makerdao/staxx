defmodule Proxy.Deployment.BaseApi do
  @moduledoc """
  Module represents basic http layer for deployment service
  """
  use HTTPoison.Base

  require Logger

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
  Make request to deployment service
  """
  @spec request(binary, binary, map()) :: {:ok, term()} | {:error, term()}
  def request(id, method, data \\ %{}) do
    req =
      %{
        id: id,
        method: method,
        data: data
      }
      |> Jason.encode!()

    url()
    |> post(req, [{"Content-Type", "application/json"}])
    |> fetch_body()
  end

  @doc """
  Load list of steps from deployment service
  """
  @spec load_steps() :: {:ok, term()} | {:error, term()}
  def load_steps() do
    random_id()
    |> request("GetInfo")
  end

  # generate random number for request
  defp random_id(), do: :rand.uniform(9_999_999_999_999_999_999_999) |> to_string()

  # Get deployment service url
  defp url(), do: Application.get_env(:proxy, :deployment_service_url)

  # Pick only needed information
  defp fetch_body({:ok, %HTTPoison.Response{body: %{"type" => "error", "result" => res}}}) do
    {:error, res}
  end

  defp fetch_body({:ok, %HTTPoison.Response{status_code: 200, body: body}}),
    do: {:ok, body}

  defp fetch_body(res), do: res
end
