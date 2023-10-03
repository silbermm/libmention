defmodule Libmention.Incoming.HandleMention do
  @moduledoc false
  import Plug.Conn

  alias Libmention.Incoming.DefaultQueue

  def init(queue_adapter: queue_adapter), do: queue_adapter
  def init(_), do: DefaultQueue

  def call(%{params: %{"source" => source, "target" => target}} = conn, queue_adapter) do
    # verify source and target 
    send_resp(conn, 200, "ok")
  end

  def call(conn, _opts) do
    send_resp(conn, 400, "invalid request")
  end
end

