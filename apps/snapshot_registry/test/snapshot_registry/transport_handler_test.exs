defmodule Staxx.SnapshotRegistry.TransportHandlerTest do
  use Staxx.SnapshotRegistry.RepoCase

  alias Staxx.Transport.Client
  alias Staxx.SnapshotRegistry.Models.Snapshot

  test "test transport handler" do
    # at the beginning of test DB is empty
    assert Repo.one(from(s in Snapshot, select: count(s.id))) == 0

    # connect to transport server and sending file
    {:ok, pid} = Client.start_link(receiver_pid: self())
    Client.connect(pid, "localhost", 3134)
    payload = %{description: "test_description", chain_type: "test_chain_type"}
    Client.send_file(pid, fixture_file(), payload)
    Process.sleep(100)
    Client.disconnect(pid)
    Process.sleep(100)

    # check the snapshot is created in DB
    assert Repo.one(from(s in Snapshot, select: count(s.id))) == 1

    # check size of test file
    %Snapshot{id: snapshot_id, description: description, chain_type: chain_type} =
      Repo.one(from(s in Snapshot))

    %File.Stat{type: :regular, size: file_size} =
      snapshot_id
      |> new_fixture_file_path()
      |> File.stat!()

    assert file_size == 445
    assert description == "test_description"
    assert chain_type == "test_chain_type"

    # remove test snapshot
    snapshot_id
    |> new_fixture_file_path()
    |> File.rm!()
  end

  defp fixture_file() do
    :snapshot_registry
    |> Application.get_env(:snapshot_fixtures_path)
    |> Path.expand()
    |> Path.join("text.txt")
  end

  defp new_fixture_file_path(snapshot_id) do
    :snapshot_registry
    |> Application.get_env(:snapshot_base_path)
    |> Path.expand()
    |> Path.join(snapshot_id)
  end
end
