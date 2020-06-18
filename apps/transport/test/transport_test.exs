defmodule Staxx.Transport.TransportTest do
  use Staxx.Transport.TestCase
  alias Staxx.Transport.Client
  alias Staxx.Transport.Server

  test "socket connecting must fail" do
    {:ok, pid} = Client.start_link(receiver_pid: self())
    Client.connect(pid, "localhost", 3322)
    Process.sleep(100)
    assert_received {:tcp_client, {:connect_failed, _reason}}
  end

  test "socket connects successfully", context do
    port = context[:port]
    args = %{receiver_pid: self(), tmp_dir: "/tmp/transfered_files", transport_port: port}
    Server.start_link(args)
    Process.sleep(100)
    {:ok, pid} = Client.start_link(receiver_pid: self())
    Client.connect(pid, "localhost", port)
    Process.sleep(100)
    assert_received {:tcp_client, {:connected, _socket}}
  end

  test "Three sockets connects successfully", context do
    port = context[:port]
    args = %{receiver_pid: self(), tmp_dir: "/tmp/transfered_files", transport_port: port}
    {:ok, server_pid} = Server.start_link(args)
    IO.inspect(server_pid, label: "server")
    Process.sleep(100)

    {:ok, pid1} = Client.start_link(receiver_pid: self())
    Client.connect(pid1, "localhost", port)
    Process.sleep(100)
    assert_received {:tcp_client, {:connected, _socket}}

    {:ok, pid2} = Client.start_link(receiver_pid: self())
    Client.connect(pid2, "localhost", port)
    Process.sleep(100)
    assert_received {:tcp_client, {:connected, _socket}}

    {:ok, pid3} = Client.start_link(receiver_pid: self())
    Client.connect(pid3, "localhost", port)
    Process.sleep(100)
    assert_received {:tcp_client, {:connected, _socket}}

    Client.disconnect(pid1)
    Client.disconnect(pid2)
    Client.disconnect(pid3)
    Process.sleep(100)
  end

  test "send binary data to server with payload and without token", context do
    tmp_dir = context[:server_tmp_dir]
    filepath = context[:filepath]
    assert_timeout = context[:assert_timeout]
    port = context[:port]
    args = %{receiver_pid: self(), tmp_dir: tmp_dir, transport_port: port}
    payload = %{description: Faker.Lorem.paragraph(), chain_type: Faker.String.base64()}

    Server.start_link(args)
    Process.sleep(1000)

    {:ok, pid} = Client.start_link(receiver_pid: self())
    Client.connect(pid, "localhost", port)
    Process.sleep(100)

    Client.send_file(pid, filepath, payload)

    assert_receive {:tcp_client, {:transfer_complete}}, assert_timeout
  end
end
