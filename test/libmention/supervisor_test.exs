defmodule Libmention.SupervisorTest do
  use Libmention.Case, async: false
  # setting async to false because the outgoing_supervisor_test.exs also
  # starts the outgoing_supervisor
  doctest Libmention.Supervisor

  import Libmention.HttpFactory

  setup :start_supervisor

  @tag outgoing: true
  test "start supervisor for outgoing webmentions" do
    # make sure the outgoing supervisor is started
    assert Process.whereis(Libmention.OutgoingSupervisor)
  end

  describe "outgoing with valid webmention" do
    @describetag outgoing: true

    setup [:expect_valid_head_request, :expect_invalid_head_request]
    setup [:expect_invalid_get_request]
    setup [:expect_valid_post_request]

    test "starts a worker and sends a webmention", %{url: url, html: html, endpoint: endpoint} do
      Libmention.Supervisor.send(url, html)
      assert_receive {:done, [url]}
      assert url == endpoint <> "/queue"
    end
  end

  describe "outgoing with no valid webmention" do
    @describetag outgoing: true

    setup [:expect_invalid_head_request, :expect_invalid_head_request]
    setup [:expect_invalid_get_request, :expect_invalid_get_request]

    test "starts a worker and doesn't send a webmention", %{url: url, html: html} do
      Libmention.Supervisor.send(url, html)
      assert_receive :done
    end
  end

  def start_supervisor(%{outgoing: true}) do
    pid = start_supervised!({Libmention.Supervisor, [outgoing: [user_agent: "test-libmention"]]})
    %{pid: pid}
  end
end
