defmodule Staxx.WebApiWeb.ApiChannelTest do
  use Staxx.WebApiWeb.ChannelCase
  alias Staxx.WebApiWeb.V1.UserSocket
  alias Staxx.WebApiWeb.V1.ApiChannel

  @moduletag :api
  @moduletag :api_channel

  setup do
    {:ok, _, socket} =
      UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(ApiChannel, "api")

    %{socket: socket}
  end

  test "List chains", %{socket: socket} do
    ref = push(socket, "list_chains", %{})
    assert_reply(ref, :ok, %{chains: _list})
  end

  describe "Test json schema validation" do
    test "start_existing should fail for incorrect payload", %{socket: socket} do
      ref = push(socket, "start_existing", %{})
      assert_reply(ref, :error, %{message: _message})
    end

    test "start should fail for incorrect payload", %{socket: socket} do
      ref = push(socket, "start", %{})
      assert_reply(ref, :error, %{message: _message})
    end
  end
end
