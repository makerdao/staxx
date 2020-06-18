defmodule Staxx.Transport.ServerUtils do
  @moduledoc """
  Utils module for socket operations.
  """

  @doc """
  Returns port number.
  """
  @spec port_for_socket() :: non_neg_integer()
  def port_for_socket(),
    do: Application.get_env(:transport, :socket_port, 3134)

  @doc """
  Returns options keyword list for socket connections.
  Options are: `:binary, active: :once, packet: 4, reuseaddr: true`
  """
  @spec options_for_socket() :: keyword()
  def options_for_socket(),
    do: [:binary, active: :once, packet: 4, reuseaddr: true]

  @doc """
  Sets options got from `Staxx.Transport.ServerUtils.options_for_socket/0` to a given socket.
  """
  @spec set_inet_options_active(port) :: :ok | {:error, term()}
  def set_inet_options_active(socket),
    do: :inet.setopts(socket, options_for_socket())
end
