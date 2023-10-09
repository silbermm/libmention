defmodule Libmention.Incoming.ReceiverPlug do
  @moduledoc """
  A Plug that can be used for incoming WebMentions.
  """

  import Plug.Conn

  alias Libmention.Incoming.DefaultQueue

  def init(opts) do
    queue_adapter = Keyword.get(opts, :queue_adaptor, DefaultQueue)
    content_validator = Keyword.get(opts, :content_validator)

    if content_validator == nil do
      raise """
      a content_validator is required to use Libmention.Incoming.ReceiverPlug
      """
    else
      %{queue_adapter: queue_adapter, content_validator: content_validator}
    end
  end

  def call(%{params: %{"source" => source, "target" => target}} = conn, %{
        queue_adapter: queue_adapter,
        content_validator: content_validator
      }) do
    # verify source and target 
    with {:ok, source_uri} <- URI.new(source),
         false <- is_nil(source_uri.scheme),
         {:ok, target_uri} <- URI.new(target),
         # make sure the source_url is reachable
         {:ok, %Req.Response{status: 200}} <- Req.get(URI.to_string(source_uri)),
         # make sure the target url accepts webmentions
         :ok <- content_validator.validate(target_uri) do
      # queue up the webmention
      send_resp(conn, 200, "ok")
    else
      _ -> send_resp(conn, 400, "invalid request")
    end
  end

  def call(conn, _opts) do
    send_resp(conn, 400, "invalid request")
  end
end
