defmodule Libmention.Outgoing.ProxyTest do
  use Libmention.Case
  use Plug.Test

  alias Libmention.Outgoing.Proxy 
  alias Libmention.Outgoing.Proxy.Router

  setup :start_proxy
  
  test "returns data" do
    conn =
      :get
      |> conn("/", "")
      |> Router.call([])

    assert conn.state == :sent
    assert conn.status == 200
  end

  defp start_proxy(_) do
    start_supervised!({Proxy, [port: 8082]})
    :ok
  end
end
