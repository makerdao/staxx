defmodule Staxx.Transport.Server do
  @moduledoc """
  Socket server module.
  Socket gets port to listen from `Staxx.Transport.ServerUtils.port_for_socket/0`
  and socket options from `Staxx.Transport.ServerUtils.options_for_socket/0`.
  Uses `Staxx.Transport.ListenerSupervisor` to supervise connection listener workers.


  Worker sends next messages and calls to the receiver process:
  * Makes call `{:tcp_server, {:auth, token}}` to make authorization with token received from client. Awaits for `true` or `false`.
  * Messages  `{:tcp_server, {:transfer_complete, token, data}}`
  when transfer complete and send auth token and map containing info about transfered file. See `Staxx.Transport.ListenerWorker` for details.
  * Messages `{:tcp_server, {:transfer_failed, token, reason}}` if transfer fails.
  """
  use GenServer

  require Logger

  alias Staxx.Transport.ListenerSupervisor
  alias Staxx.Transport.ServerUtils
  alias Staxx.Transport.FileUtils

  @doc false
  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  @impl true
  @doc """
  Starts listening socket.
  Receives receiver pid and temporary directory as arguments.
  Saves socket in to state.
  """
  @spec init(%{
          receiver_pid: pid(),
          tmp_dir: binary() | Path.t(),
          transport_port: non_neg_integer()
        }) ::
          {:ok, map(), {:continue, Socket}}
  def init(%{receiver_pid: receiver_pid, tmp_dir: tmp_dir, transport_port: port}) do
    {:ok, socket} = :gen_tcp.listen(port, ServerUtils.options_for_socket())

    {:ok, supervisor_pid} = Staxx.Transport.ListenerSupervisor.start_link()

    Logger.info(
      "Server for socket #{inspect(socket)} on port #{port} started with pid #{inspect(self())}."
    )

    {:ok,
     %{
       socket: socket,
       tmp_dir: tmp_dir,
       supervisor_pid: supervisor_pid,
       receiver_pid: receiver_pid
     }, {:continue, socket}}
  end

  @impl true
  def handle_continue(
        socket,
        %{tmp_dir: tmp_dir, supervisor_pid: supervisor_pid, receiver_pid: receiver_pid} = state
      ) do
    FileUtils.create_rand_dir(tmp_dir)
    accept_loop(socket, tmp_dir, receiver_pid, supervisor_pid)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{socket: socket} = _state) do
    Logger.info("Terminating transport server for socket: #{inspect(socket)}")
    :gen_tcp.close(socket)
  end

  # Infinite loop to accept connections.
  # Accepts connection to socket and starts listener worker under `Staxx.Transport.ListenerSupervisor`.
  # TODO: rewrite as a pool.
  defp accept_loop(socket, tmp_dir, receiver_pid, supervisor_pid) do
    :gen_tcp.accept(socket)
    |> case do
      {:ok, client} ->
        ListenerSupervisor.start_listener(supervisor_pid, client, {tmp_dir, receiver_pid})

      {:error, reason} ->
        Logger.error("Accept socket connection error #{inspect(reason)}")
    end

    accept_loop(socket, tmp_dir, receiver_pid, supervisor_pid)
  end
end
