defmodule Staxx.EventStream.EventStreamTest do
  use ExUnit.Case

  alias Staxx.EventStream
  alias Staxx.EventStream.Test.EventSubscriber

  @moduletag :event_stream

  @receive_timeout 200

  setup do
    {:ok, _pid} = EventSubscriber.start_link(self())
    :ok
  end

  test "receive mesasages on subscribe" do
    # don't receive the message because haven't subscription
    EventStream.dispatch({:chain, "test_msg"})
    refute_receive {:chain, "test_msg"}

    # subscribe to the EventSubscriber
    EventStream.subscribe({EventSubscriber, [".*"]})
    # timeout for subscribe
    Process.sleep(@receive_timeout)

    # receive the chain message
    EventStream.dispatch({:chain, "test_msg"})
    assert_receive {:chain, "test_msg"}, @receive_timeout

    # receive the message with id
    EventStream.dispatch(%{id: "fake_id", msg: "test"})
    assert_receive {:chain, "test", "fake_id"}, @receive_timeout

    # don't receive a message of the unregistered topic
    EventStream.dispatch({:not_registered_topic, "test_msg"})
    refute_receive {:not_registered_topic, "test_msg"}, @receive_timeout

    # unsubscribe from the EventSubscriber
    EventStream.unsubscribe(EventSubscriber)
    # timeout for unsubscribe
    Process.sleep(@receive_timeout)

    # don't receive the message because haven't subscription
    EventStream.dispatch({:chain, "test_msg"})
    refute_receive {:chain, "test_msg"}, @receive_timeout
  end
end
