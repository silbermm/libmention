defmodule Libmention.Outgoing.Proxy.Router do
  @moduledoc false
  use Plug.Router, copy_opts_to_assign: :proxy_opts

  alias Libmention.Outgoing.Proxy.HandleDiscover
  alias Libmention.Outgoing.Proxy.HandleMentions
  alias Libmention.Outgoing.Proxy.SentMentions

  plug(Plug.Logger, log: :debug)
  plug(Plug.Static, at: "/static", from: {:libmention, "priv/static"}, only: ~w(images css))
  plug(Plug.Parsers, parsers: [:urlencoded, {:json, json_decoder: Jason}])
  plug(:match)
  plug(:dispatch)

  forward("/sent", to: SentMentions)
  post("/webmentions", to: HandleMentions)

  head("/discover", to: HandleDiscover)
  get("/discover", to: HandleDiscover)

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
