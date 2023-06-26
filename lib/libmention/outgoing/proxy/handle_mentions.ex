defmodule Libmention.Outgoing.Proxy.HandleMentions do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    %{"proxy_for" => for, "source" => source, "target" => target} = conn.params

    _ =
      :ets.insert(
        Keyword.get(conn.assigns.proxy_opts, :webmentions_table),
        {for, %{source: source, target: target, timestamp: DateTime.utc_now()}}
      )

    send_resp(conn, 200, "ok")
  end
end
