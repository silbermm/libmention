defmodule Libmention.Outgoing.WorkerSupervisorTest do
  use ExUnit.Case, async: true
  doctest Libmention.Outgoing.WorkerSupervisor

  alias Libmention.Outgoing.WorkerSupervisor

  @opts [user_agent: "test-mention"]

  setup do
    start_supervised!({WorkerSupervisor, @opts})
    :ok
  end

  describe "process_content/2" do
    test "starts a child process" do
      {:ok, pid} = WorkerSupervisor.process_content("https://test.me", "")
      assert Process.alive?(pid)
    end
  end
end
