defmodule Libmention.Incoming.ReceiverPlug do
  @moduledoc """

  """
  use Plug.Router
  alias Libmention.Incoming.HandleMention

  plug :match
  plug :dispatch

  # receive webmention
  post "/", to: HandleMention

  match _ do
    send_resp(conn, 404, "oops")
  end 
end
