defmodule Staxx.Transport.Client do
  @moduledoc """
  Socket client module.
  Client can connect to the server by TCP.
  Client can send binary data packets to the server.
  Client can send file content to the server.

  Authentication with token supported. If server refuses auth token, client disconnects form server.

  Client send next info messages to the receiver process:
  * `{:tcp_client, {connected}}` if client connected successfuly.
  * `{:tcp_client, {connect_failed, reason}}` if client couldn't connect.
  * `{:tcp_client, {:transfer_complete}}` if file transfer complete successfuly.
  * `{:tcp_client, {:transfer_failed, reason}}` if file transfer failed.
  * `{:tcp_client, {:auth_success}}` if server accepts auth token sent by client.
  * `{:tcp_client, {:auth_failed}}` if server refuses auth token sent by client.
  * `{:tcp_client, {:closed}}` if connection closed.
  """
  use GenServer

  require Logger

  import Staxx.Transport.DataUtils
  alias Staxx.Transport.FileUtils

  @socket_opts [
    :binary,
    active: :once,
    packet: 4,
    reuseaddr: true
  ]

  @doc """
  Starts current module as a `GenServer` process.
  Receives `{:receiver_pid, pid}` keyword as status messages receiver process pid.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  @impl true
  @doc false
  def init(receiver_pid: receiver_pid),
    do: {:ok, %{socket: nil, data_stream: nil, receiver_pid: receiver_pid}}

  #
  # API FUNCTIONS
  #
  @doc """
  Sends given binary data packet to the server.
  """
  @spec send_data(pid(), binary) :: :ok
  def send_data(pid, data) when is_binary(data), do: GenServer.cast(pid, {:send_data, data})

  @doc """
  Sends file by given path to the server.
  May send some payload as a map structure (optional).
  Uses authorize token to make authorization (optional).
  Uses `Stream` to read file content by chunks.
  Sends `{:tcp_client, {:transfer_complete}}`, `{:tcp_client, {:transfer_failed, reason}}`,
  `{:tcp_client, {:auth_success}}`, `{:tcp_client, {:auth_failed}}` messages to the receiver process.
  """
  @spec send_file(pid(), binary() | Path.t(), map(), binary()) :: :ok
  def send_file(pid, path, payload \\ %{}, auth_token \\ ""),
    do: GenServer.cast(pid, {:send_file, path, auth_token, payload})

  @doc """
  Connects to a server by given url, on a given port.
  Sends `{:tcp_client, {connected}}` or `{:tcp_client, {connect_failed, reason}}` messages to the receiver process.
  """
  @spec connect(pid(), binary(), non_neg_integer()) :: :ok
  def connect(pid, host, port), do: GenServer.cast(pid, {:connect, {host, port}})

  @doc """
  Disconnects from a socket.
  """
  @spec disconnect(pid()) :: :ok
  def disconnect(pid), do: GenServer.cast(pid, {:disconnect})

  def handle_cast({:send_file, path, token, payload}, state) do
    {:ok, md5} = FileUtils.md5_for_file(path)
    size = FileUtils.size_of_file(path)

    self_pid = self()

    data_stream = send_data_stream(token, path, md5, size, &send_data(self_pid, &1), payload)

    new_state = Map.put(state, :data_stream, data_stream)

    #
    # Send first element of the data stream - AUTH packet
    data_stream
    |> Stream.run()

    {:noreply, new_state}
  end

  @impl true
  @doc false
  def handle_cast({:disconnect}, %{socket: socket} = state) do
    :gen_tcp.close(socket)
    {:noreply, state}
  end

  @impl true
  @doc false
  def handle_cast({:connect, {host, port}}, %{receiver_pid: receiver_pid} = state) do
    host
    |> String.to_charlist()
    |> :gen_tcp.connect(port, @socket_opts)
    |> case do
      {:ok, socket} ->
        Logger.info("Client connected to socket: #{inspect(socket)}")
        send_status(receiver_pid, {:connected, socket})
        {:noreply, Map.put(state, :socket, socket)}

      {:error, reason} ->
        Logger.error("Client connect failed  with error: #{inspect(reason)}")
        send_status(receiver_pid, {:connect_failed, reason})
        {:noreply, state}
    end
  end

  @impl true
  @doc false
  def handle_cast({:send_data, data}, %{socket: socket} = state) do
    :gen_tcp.send(socket, data)
    {:noreply, state}
  end

  @impl true
  @doc false
  def handle_info({:tcp, _socket, data}, %{socket: socket} = state) do
    :inet.setopts(socket, @socket_opts)
    handle_socket_response(data, state)
  end

  @impl true
  @doc false
  def handle_info({:tcp_closed, socket}, %{receiver_pid: receiver_pid} = state) do
    Logger.info("Client: connection to server closed #{inspect(socket)}")
    send_status(receiver_pid, {:closed})
    :gen_tcp.close(socket)
    {:noreply, state}
  end

  @impl true
  @doc false
  def handle_info({:tcp_error, socket, reason}, %{receiver_pid: receiver_pid} = state) do
    Logger.info("Client: socket error #{inspect(socket)} reason #{inspect(reason)}")
    send_status(receiver_pid, {:error, reason})
    {:noreply, state}
  end

  @impl true
  @doc false
  def terminate(_reason, %{socket: socket} = _state),
    do: Logger.info("Client: Terminating client on socket #{inspect(socket)}")

  @doc """
  Handles data received from server.
  Handles "AUTH_SUCCESS", "AUTH_FAILED", "COMPLETE" packets.
  """
  @spec handle_socket_response(binary(), map()) :: {:noreply, term()}
  def handle_socket_response(
        <<"AUTH_SUCCESS">>,
        %{socket: socket, receiver_pid: receiver_pid} = state
      ) do
    Logger.info("Client: authentication for socket #{inspect(socket)} successful.")
    send_status(receiver_pid, {:auth_success})
    {:noreply, state}
  end

  def handle_socket_response(
        <<"AUTH_FAILED">>,
        %{socket: socket, receiver_pid: receiver_pid} = state
      ) do
    Logger.info("Client: #{inspect(socket)} auth failed. Closing connection.")
    send_status(receiver_pid, {:auth_failed})
    disconnect(self())
    {:noreply, state}
  end

  def handle_socket_response(
        <<"COMPLETE">>,
        %{socket: socket, receiver_pid: receiver_pid} = state
      ) do
    Logger.info("Client: #{inspect(socket)} file transfer complete. Closing connection.")
    send_status(receiver_pid, {:transfer_complete})
    {:noreply, state}
  end

  def handle_socket_response(
        <<"WRONG_HASH">>,
        %{socket: socket, receiver_pid: receiver_pid} = state
      ) do
    reason = "File hashes doesn't match"
    Logger.info("Client: #{inspect(socket)} file transfer failed with reason: #{reason}.")
    send_status(receiver_pid, {:transfer_failed, reason})
    {:noreply, state}
  end

  defp send_status(receiver_pid, status), do: send(receiver_pid, {:tcp_client, status})
end
