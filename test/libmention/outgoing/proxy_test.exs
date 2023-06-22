defmodule Libmention.Outgoing.ProxyTest do
  use Libmention.Case
  use Plug.Test

  alias Libmention.Outgoing.Proxy
  alias Libmention.Outgoing.Proxy.Router

  setup :start_proxy

  test "sent" do
    conn =
      :get
      |> conn("/sent", "")
      |> Router.call(table: Proxy.proxy_table())

    assert conn.state == :sent
    assert conn.status == 200
  end

  defp start_proxy(_) do
    start_supervised!({Proxy, [port: 8082]})
    :ok
  end
end
