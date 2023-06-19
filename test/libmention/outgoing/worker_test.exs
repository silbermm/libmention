defmodule Libmention.Outgoing.WorkerTest do
  use Libmention.Case

  import Libmention.HttpFactory
  alias Libmention.EtsStorage
  alias Libmention.Outgoing.Worker

  @default_opts [user_agent: "test-libmention"]

  setup :create_ets_table
  setup :start_worker

  describe "start worker, process html, and send webmention" do
    setup [:expect_valid_head_request, :expect_invalid_head_request]
    setup [:expect_invalid_get_request]
    setup [:expect_valid_post_request]

    test "sends webmention for valid endpoint", %{pid: pid, url: url, html: html} do
      Worker.process(pid, url, html)
      assert_receive {:done, _}
    end
  end

  describe "start woker, no head links" do
    setup [:expect_invalid_head_request, :expect_invalid_head_request]
    setup [:expect_valid_get_request, :expect_invalid_get_request]
    setup [:expect_valid_post_request]

    test "sends webmention for valid endpoint from get request", %{pid: pid, url: url, html: html} do
      Worker.process(pid, url, html)
      assert_receive {:done, _}
    end
  end

  describe "start worker, no valid links" do
    setup [:expect_invalid_head_request, :expect_invalid_head_request]
    setup [:expect_invalid_get_request, :expect_invalid_get_request]

    test "no valid endpoint sends no webmentions", %{pid: pid, url: url, html: html} do
      Worker.process(pid, url, html)
      assert_receive :done
    end
  end

  describe "invalid post when sending webmention" do
    setup [:expect_valid_head_request, :expect_invalid_head_request]
    setup [:expect_invalid_get_request]
    setup [:expect_invalid_post_request]

    test "fails to send webmention for valid endpoint", %{pid: pid, url: url, html: html} do
      Worker.process(pid, url, html)
      assert_receive {:done, []}
    end
  end

  describe "webmention storage for valid webmention" do
    setup [:expect_valid_head_request, :expect_invalid_head_request]
    setup [:expect_invalid_get_request]
    setup [:expect_valid_post_request]

    test "saves successfully sent webmention", %{pid: pid, url: url, html: html, good_webmention_url: good_url} do
      Worker.process(pid, url, html)
      assert_receive {:done, _}

      # get the value out of ETS
      entity = EtsStorage.get(%{source_url: url, target_url: good_url})
      assert entity.status == :sent
    end
  end

 describe "webmention storage for invalid webmentions" do
    setup [:expect_invalid_head_request, :expect_invalid_head_request]
    setup [:expect_invalid_get_request, :expect_invalid_get_request]

    test "saves not found webmentions", %{pid: pid, url: url, html: html, good_webmention_url: good_url, bad_webmention_url: bad_url} do
      Worker.process(pid, url, html)
      assert_receive :done

      # get the value out of ETS
      entity = EtsStorage.get(%{source_url: url, target_url: good_url})
      assert entity.status == :not_found

      # get the value out of ETS
      entity = EtsStorage.get(%{source_url: url, target_url: bad_url})
      assert entity.status == :not_found
    end
  end


  def create_ets_table(_context) do
    :ets.new(EtsStorage.table_name(), [:public, :named_table])
    :ok
  end

  def start_worker(_context) do
    spec = %{
      id: Worker,
      start: {Worker, :start_link, [@default_opts, []]}
    }

    {:ok, pid} = start_supervised(spec)
    %{pid: pid}
  end
end
