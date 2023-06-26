defmodule Libmention.Outgoing.OutgoingWithProxyTest do
  use Libmention.Case, async: false

  alias Libmention.Outgoing.Proxy
  alias Libmention.Outgoing

  describe "when discovering a webmention endpoint and the proxy is enabled" do
    setup :start_proxy

    setup do
      Application.put_env(:libmention, :http_api, Req)
      on_exit(fn -> Application.put_env(:libmention, :http_api, MockHttp) end)
    end

    test "sends the request to the proxy", %{good_webmention_url: webmention_link} do
      opts = [proxy: []]

      # make sure the table is empty
      # assert [] = :ets.lookup(Proxy.proxy_table(), endpoint)

      _ = Outgoing.discover(webmention_link, opts)

      # validate that the proxy ets table has the entry
    end
  end

  describe "when sending a webmention and the proxy is enabled" do
    setup :start_proxy

    setup do
      Application.put_env(:libmention, :http_api, Req)
      on_exit(fn -> Application.put_env(:libmention, :http_api, MockHttp) end)
    end

    test "sends the request to the proxy, saves the data", %{
      endpoint: endpoint,
      good_webmention_url: webmention_link,
      url: url
    } do
      opts = [proxy: []]

      # make sure the table is empty
      assert [] = :ets.lookup(Proxy.webmentions_table(), endpoint)

      _ = Outgoing.send(endpoint, url, webmention_link, opts)

      # validate that the proxy ets table has the entry
      assert [{^endpoint, %{source: ^url, target: ^webmention_link}}] =
               :ets.lookup(Proxy.webmentions_table(), endpoint)
    end
  end

  defp start_proxy(_) do
    start_supervised!({Libmention.Outgoing.Proxy, [port: 8082]})
    :ok
  end
end
