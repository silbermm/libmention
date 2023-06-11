defmodule Libmention.SupervisorTest do
  use ExUnit.Case, async: true
  doctest Libmention.Supervisor

  test "start supervisor for outgoing webmentions" do
    # start the outgoing supervisor by passing in the options
    assert start_supervised!({Libmention.Supervisor, [outgoing: [user_agent: "libmention"]]})

    # make sure the outgoing supervisor is started
    assert Process.whereis(Libmention.OutgoingSupervisor)
  end
end
