defmodule Libmention.Incoming.ReceiverTest do
  use ExUnit.Case, async: true

  describe "valid target" do
    setup [:setup_with_fake_receiver, :with_incoming_supervisor]

    @describetag validate_return: true

    test "receiver validate works", %{receiver: receiver} do
      assert receiver.validate("https://whatver.com") == true
    end

    test "receiver queues up request", %{receiver: receiver} do
      target_uri = URI.new!("https://target.com")
      source_uri = URI.new!("https://source.com")
      id = Libmention.Incoming.Receiver.queue(receiver, target_uri, source_uri)
      saved_queue = :sys.get_state(Libmention.Incoming.ReceiverTest.FakeReceiver).queue

      assert %{id: ^id, source_url: %URI{host: "source.com"}, target_url: %URI{host: "target.com"}} =
               :queue.get(saved_queue)
    end

    @tag timeout: :short
    test "receiver processes queue when timeout hit", %{receiver: receiver} do
      target_uri = URI.new!("https://target.com")
      source_uri = URI.new!("https://source.com")

      receiver.queue(target_uri, source_uri)
      saved_queue = :sys.get_state(Libmention.Incoming.ReceiverTest.FakeReceiver).queue

      assert %{source_url: %URI{host: "source.com"}, target_url: %URI{host: "target.com"}} =
               :queue.get(saved_queue)

      Process.sleep(1)
      saved_queue = :sys.get_state(Libmention.Incoming.ReceiverTest.FakeReceiver).queue
      assert :queue.is_empty(saved_queue)
    end
  end

  describe "when the target is invalid" do
    setup [:setup_with_fake_receiver, :with_incoming_supervisor]

    @describetag validate_return: false

    test "then the receiver validate fails", %{receiver: receiver} do
      assert receiver.validate("https://whatver.com") == :not_supported
    end
  end

  defp with_incoming_supervisor(_context) do
    start_supervised(
      {Libmention.IncomingSupervisor, receiver: Libmention.Incoming.ReceiverTest.FakeReceiver}
    )

    :ok
  end

  defp setup_with_fake_receiver(%{validate_return: true, timeout: :short}) do
    defmodule FakeReceiver do
      use Libmention.Incoming.Receiver, timeout: 1

      def validate(_url), do: true
    end

    %{receiver: FakeReceiver}
  end

  defp setup_with_fake_receiver(%{validate_return: true}) do
    defmodule FakeReceiver do
      use Libmention.Incoming.Receiver, timeout: 1_000

      def validate(_url), do: true
    end

    %{receiver: FakeReceiver}
  end

  defp setup_with_fake_receiver(_) do
    defmodule FakeReceiver do
      use Libmention.Incoming.Receiver
    end

    %{receiver: FakeReceiver}
  end
end
