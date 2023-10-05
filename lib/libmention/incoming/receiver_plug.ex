defmodule Libmention.Incoming.ReceiverPlug do
  @moduledoc """
  A Plug that can be used for incoming WebMentions.
  """

  import Plug.Conn

  alias Libmention.Incoming.HandleMention

  def init(queue_adapter: queue_adapter), do: queue_adapter

  def init(opts) do
    dbg(opts)
    DefaultQueue
  end

  def call(%{params: %{"source" => source, "target" => target}} = conn, _queue_adapter) do
    # verify source and target are valid URLs
    with {:ok, source_uri} <- URI.new(source),
         {:ok, target_uri} <- URI.new(target) do
      # check that target is a valid resource for which it can accept webmentions
    end

    # queue the webmention

    # if showing a status page, send 201 with a Location header with status URL 

    # if not showing a status page, send 202

    send_resp(conn, 200, "ok")
  end

  def call(conn, opts) do
    dbg(opts)
    send_resp(conn, 400, "invalid request")
  end
end
