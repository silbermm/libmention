defmodule Libmention.Outgoing.Proxy.HandleDiscover do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(%{method: "HEAD"} = conn, _opts) do
    table = Keyword.get(conn.assigns.proxy_opts, :discovery_table)
    %{"proxy_for" => for} = conn.params

    _ = :ets.insert(table, {for, %{timestamp: DateTime.utc_now(), method: :head}})

    send_resp(conn, 200, valid_link_response(for))
  end

  def call(%{method: "GET"} = conn, _opts) do
    table = Keyword.get(conn.assigns.proxy_opts, :discovery_table)
    %{"proxy_for" => for} = conn.params

    _ = :ets.insert(table, {for, %{timestamp: DateTime.utc_now(), method: :get}})

    send_resp(conn, 200, "ok")
  end

  defp valid_link_response(target) do
    ~s"""
    <link href="#{target}/webmention" rel="webmention"  
    """
  end
end
