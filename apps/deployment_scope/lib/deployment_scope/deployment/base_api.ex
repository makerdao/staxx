defmodule Staxx.DeploymentScope.Deployment.BaseApi do
  @moduledoc """
  Module represents basic http layer for deployment service
  """
  use HTTPoison.Base

  require Logger

  @random_max 9_999_999_999_999_999_999_999

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

  @doc """
  Request service to reload sources for deployment scripts
  """
  @spec update_source() :: {:ok, term()} | {:error, term()}
  def update_source() do
    random_id()
    |> request("UpdateSource")
  end

  @doc """
  Run deployment step with list of env variables
  """
  @spec run(binary, 1..9, map()) :: {:ok, term()} | {:error, term()}
  def run(id, step, env_vars \\ %{}) when step in 1..9 do
    data = %{
      stepId: step,
      envVars: env_vars
    }

    request(id, "Run", data)
  end

  @doc """
  Check out new commit for deployemnt scripts
  """
  @spec checkout(binary, binary) :: {:ok, term} | {:error, term}
  def checkout(id, commit) when is_binary(commit) do
    data = %{
      commit: commit
    }

    request(id, "Checkout", data)
  end

  @doc """
  Will load list of available comits from deployment scripts repo
  """
  @spec get_commit_list() :: {:ok, term} | {:error, term}
  def get_commit_list() do
    random_id()
    |> request("GetCommitList")
  end

  # generate random number for request
  def random_id(), do: @random_max |> :rand.uniform() |> to_string()

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
