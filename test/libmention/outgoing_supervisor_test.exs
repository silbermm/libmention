defmodule Libmention.OutgoingSupervisorTest do
  use ExUnit.Case, async: true
  doctest Libmention.OutgoingSupervisor

  alias Libmention.OutgoingSupervisor

  @opts [user_agent: "test-mention"]

  setup do
    start_supervised!({OutgoingSupervisor, @opts})
    :ok
  end

  describe "process_content/2" do
    test "starts a child process" do
      {:ok, pid} = OutgoingSupervisor.process_content("https://test.me", "")
      assert Process.alive?(pid)
    end
  end
end
