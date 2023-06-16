defmodule Libmention.SupervisorTest do
  use ExUnit.Case, async: false
  # setting async to false because the outgoing_supervisor_test also
  # starts the outgoing_supervisor
  doctest Libmention.Supervisor

  test "start supervisor for outgoing webmentions" do
    # start the outgoing supervisor by passing in the options
    assert start_supervised!({Libmention.Supervisor, [outgoing: [user_agent: "libmention"]]})

    # make sure the outgoing supervisor is started
    assert Process.whereis(Libmention.OutgoingSupervisor)
  end
end
