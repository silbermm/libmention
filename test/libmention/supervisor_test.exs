defmodule Libmention.SupervisorTest do
  use Libmention.Case, async: false
  # setting async to false because the outgoing_supervisor_test.exs also
  # starts the outgoing_supervisor
  doctest Libmention.Supervisor

  import Libmention.HttpFactory
  alias Libmention.EtsStorage

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

  describe "outgoing with updated content" do
    @describetag outgoing: true

    setup [:expect_valid_head_request, :expect_invalid_head_request]
    setup [:expect_invalid_get_request]
    setup [:expect_valid_post_request]
    setup [:expect_valid_post_request]

    test "sends first webmention for valid endpoint, then again for updated content", %{
      url: url,
      html: html,
      updated_html: updated_html,
      good_webmention_url: good_url
    } do
      Libmention.Supervisor.send(url, html)
      assert_receive {:done, _}

      entity = EtsStorage.get(%{source_url: url, target_url: good_url})
      assert entity.status == :sent

      Libmention.Supervisor.send(url, updated_html)
      assert_receive {:done, _}
    end
  end

  describe "outgoing without updated content" do
    @describetag outgoing: true

    setup [:expect_valid_head_request, :expect_invalid_head_request]
    setup [:expect_invalid_get_request]
    setup [:expect_valid_post_request]

    test "sends first webmention for valid endpoint only once if content not updated", %{
      url: url,
      good_webmention_url: good_url,
      html: html
    } do
      Libmention.Supervisor.send(url, html)
      assert_receive {:done, _}

      entity = EtsStorage.get(%{source_url: url, target_url: good_url})
      assert entity.status == :sent

      Libmention.Supervisor.send(url, html)
      assert_receive :done
    end
  end

  def start_supervisor(%{outgoing: true}) do
    pid = start_supervised!({Libmention.Supervisor, [outgoing: [user_agent: "test-libmention"]]})
    %{pid: pid}
  end
end
