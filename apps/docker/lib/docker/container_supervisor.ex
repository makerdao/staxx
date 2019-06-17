defmodule Docker.ContainerSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  alias Docker.Struct.Container

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start new container PID
  """
  @spec start_container(Container.t()) :: DynamicSupervisor.on_start_child()
  def start_container(%Container{} = container),
    do: DynamicSupervisor.start_child(__MODULE__, {Container, container})
end
