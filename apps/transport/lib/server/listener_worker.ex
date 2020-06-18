defmodule Staxx.Transport.ListenerWorker do
  @moduledoc """
  Worker module to listen given socket, receive data and process data.
   Worker sends next messages and calls to the receiver process:
  * Makes call `{:tcp_server, {:auth, token}}` to make authorization with token received from client. Awaits for `true` or `false`.
  * Messages  `{:tcp_server, {:transfer_complete, token, data}}`
  when transfer complete and send auth token and `%{filename: filename, filepath: tmp_filepath, payload: payload}` map.
  * Messages `{:tcp_server, {:transfer_failed, token, reason}}` if transfer fails.

  Worker closes connection and dies after transfer complete or failed. (But this is discussable.)
  Worker closes connection and dies if authentication fails.
  """
  use GenServer, restart: :transient

  require Logger

  import Staxx.Transport.DataUtils

  alias Staxx.Transport.ServerUtils
  alias Staxx.Transport.FileUtils

  def start_link(args),
    do: GenServer.start_link(__MODULE__, args)

  @impl true
  @spec init({any, any, any}) :: {:ok, map()}
  def init({socket, tmp_dir, receiver_pid}) do
    Logger.info("Starting listener worker for socket #{inspect(socket)}")

    {:ok,
     %{
       socket: socket,
       tmp_dir: tmp_dir,
       receiver_pid: receiver_pid,
       tmp_filepath: nil,
       file_hash: nil,
       filename: nil,
       file_size: 0,
       token: nil,
       payload: nil
     }}
  end

  @doc """
  Calls receiver process to check authorization token.
  If token is empty string, always returns true
  """
  @spec authorize_with_token(binary(), pid()) :: term()
  def authorize_with_token("", _receiver_pid), do: true

  def authorize_with_token(token, receiver_pid),
    do: GenServer.call(receiver_pid, {:tcp_server, {:auth, token}})

  @doc """
  Sends to the receiver process message that file transfer complete and sends file related data and token.
  """
  @spec send_complete_event(pid(), binary(), map()) :: :ok
  def send_complete_event(receiver_pid, token, data),
    do: send(receiver_pid, {:tcp_server, {:transfer_complete, token, data}})

  @doc """
  Sends to the receiver process message that file transfer failed and sends token and error reason.
  """
  @spec send_failed_event(pid(), binary(), term()) :: :ok
  def send_failed_event(receiver_pid, token, reason),
    do: send(receiver_pid, {:tcp_server, {:transfer_failed, token, reason}})

  @impl true
  def handle_info(
        {:tcp, _, <<"AUTH", token::binary>>},
        %{socket: socket, receiver_pid: receiver_pid} = state
      ) do
    case authorize_with_token(token, receiver_pid) do
      true ->
        Logger.info("Auth with token #{token} successfull")
        :gen_tcp.send(socket, auth_response_packet(true))

        new_state =
          state
          |> Map.put(:token, token)

        ServerUtils.set_inet_options_active(socket)
        {:noreply, new_state}

      false ->
        :gen_tcp.send(socket, auth_response_packet(false))
        Logger.error("Auth with token #{token} failed")
        {:stop, :normal, state}
    end
  end

  @impl true
  def handle_info(
        {:tcp, _, <<"META", _rest::binary>> = data},
        %{tmp_dir: tmp_dir, socket: socket} = state
      ) do
    {md5, size, filename, payload} = parse_meta_packet(data)
    tmp_filepath = FileUtils.new_random_filepath(tmp_dir)
    FileUtils.create_file(tmp_filepath)

    new_state =
      state
      |> Map.put(:file_hash, md5)
      |> Map.put(:filename, filename)
      |> Map.put(:file_size, size)
      |> Map.put(:tmp_filepath, tmp_filepath)
      |> Map.put(:payload, payload)

    ServerUtils.set_inet_options_active(socket)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(
        {:tcp, _, <<"EOF">> = _data},
        %{
          tmp_filepath: tmp_filepath,
          file_hash: file_hash,
          token: token,
          socket: socket,
          receiver_pid: receiver_pid,
          filename: filename,
          payload: payload
        } = state
      ) do
    with {:ok, hash} <- FileUtils.md5_for_file(tmp_filepath),
         true <- hash == file_hash do
      Logger.info("MD5 hash is good for file #{tmp_filepath}")
      :gen_tcp.send(socket, complete_packet())

      send_complete_event(receiver_pid, token, %{
        filename: filename,
        filepath: tmp_filepath,
        payload: payload
      })
    else
      false ->
        Logger.error("MD5 hash is not good for file #{tmp_filepath}")
        :gen_tcp.send(socket, wrong_hash_packet())
        send_failed_event(receiver_pid, token, {:error, "File hash doesn't match"})

      {:error, :enoent} ->
        Logger.error("File #{tmp_filepath} does not exist")
        :gen_tcp.send(socket, wrong_hash_packet())
        send_failed_event(receiver_pid, token, {:error, "File does not exist"})
    end

    {:stop, :normal, state}
  end

  @impl true
  def handle_info(
        {:tcp, _socket, data},
        %{socket: socket, tmp_filepath: tmp_filepath} = state
      ) do
    FileUtils.append_data_to_file(tmp_filepath, data)
    ServerUtils.set_inet_options_active(socket)
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, socket}, state) do
    Logger.info("Socket #{inspect(socket)} closed")
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:tcp_error, socket, reason}, _state) do
    Logger.error("Socket #{inspect(socket)} error: #{reason}")
    {:stop, :normal, reason}
  end

  @impl true
  def terminate(_reason, %{socket: socket} = _state) do
    Logger.info("Terminating socket listener #{inspect(socket)}")
    :ok
  end
end
