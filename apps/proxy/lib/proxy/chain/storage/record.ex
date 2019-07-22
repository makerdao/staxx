defmodule Staxx.Proxy.Chain.Storage.Record do
  @moduledoc """
  Details for chain process that will be stored into DB
  """

  alias Staxx.Proxy.Chain.State
  alias Staxx.Proxy.Chain.Storage

  @type t :: %__MODULE__{
          id: binary,
          status: State.status(),
          config: map(),
          chain_details: map(),
          deploy_data: map(),
          deploy_step: map(),
          deploy_hash: binary
        }

  defstruct id: nil,
            status: :initializing,
            config: nil,
            chain_details: nil,
            deploy_data: nil,
            deploy_step: nil,
            deploy_hash: nil

  @doc """
  Try to load existing data from DB and apply state status
  """
  @spec from_state(State.t()) :: t()
  def from_state(%State{id: id, status: status}) do
    case Storage.get(id) do
      nil ->
        %__MODULE__{id: id, status: status}

      record ->
        %__MODULE__{record | status: status}
    end
  end

  @spec status(t(), State.status()) :: t()
  def status(%__MODULE__{} = record, status),
    do: %__MODULE__{record | status: status}

  @spec config(t(), map()) :: t()
  def config(%__MODULE__{} = record, config),
    do: %__MODULE__{record | config: config}

  @spec chain_details(t(), term()) :: t()
  def chain_details(%__MODULE__{} = record, details),
    do: %__MODULE__{record | chain_details: details}

  @spec deploy_step(t(), map()) :: t()
  def deploy_step(%__MODULE__{} = record, step),
    do: %__MODULE__{record | deploy_step: step}

  @spec deploy_hash(t(), binary()) :: t()
  def deploy_hash(%__MODULE__{} = record, hash),
    do: %__MODULE__{record | deploy_hash: hash}

  @spec deploy_data(t(), term()) :: t()
  def deploy_data(%__MODULE__{} = record, data),
    do: %__MODULE__{record | deploy_data: data}

  @spec merge_deploy_details(t(), t()) :: t()
  def merge_deploy_details(%__MODULE__{} = record, %__MODULE__{
        deploy_data: deploy_data,
        deploy_step: deploy_step,
        deploy_hash: deploy_hash
      }) do
    %__MODULE__{
      record
      | deploy_data: deploy_data,
        deploy_step: deploy_step,
        deploy_hash: deploy_hash
    }
  end

  def merge_deploy_details(%__MODULE__{} = rec, _),
    do: rec

  @spec store(t()) :: t()
  def store(%__MODULE__{} = rec) do
    Storage.store(rec)
    rec
  end
end
