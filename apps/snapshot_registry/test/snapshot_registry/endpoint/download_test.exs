defmodule Staxx.SnapshotRegistry.RouterDownloadTest do
  use ExUnit.Case
  use Plug.Test

  alias Staxx.SnapshotRegistry.Router

  @opts Router.init([])

  test "download with range" do
    conn =
      conn(:get, "/download", "")
      |> put_req_header("range", "bytes=200-300")
      |> Router.call(@opts)

    assert conn.status == 206
  end

  test "download without range" do
    conn =
      conn(:get, "/download", "")
      |> Router.call(@opts)

    assert conn.status == 200
  end

  describe "download with invalid range" do
    test "case 1" do
      conn =
        conn(:get, "/download", "")
        |> put_req_header("range", "bytes=-1-100")
        |> Router.call(@opts)

      assert conn.status == 416
    end

    test "case 2" do
      conn =
        conn(:get, "/download", "")
        |> put_req_header("range", "bytes=1--100")
        |> Router.call(@opts)

      assert conn.status == 416
    end

    test "case 3" do
      conn =
        conn(:get, "/download", "")
        |> put_req_header("range", "bytes=101-100")
        |> Router.call(@opts)

      assert conn.status == 416
    end

    test "case 4" do
      conn =
        conn(:get, "/download", "")
        |> put_req_header("range", "bytes=446-800")
        |> Router.call(@opts)

      assert conn.status == 416
    end
  end
end
