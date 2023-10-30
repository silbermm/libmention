defmodule Libmention.Incoming.ReceiverPlug do
  @moduledoc """
  A Plug that can be used for incoming WebMentions.

  A receiver module that implements `Libmention.Incoming.Receiver`
  is required for this plug to be used.

  When forwarded to this plug, a POST and GET route is exposed.

  POSTing will allow creation of WebMentions and return an `id`

  GET with the id will return the status of the webmention.

  ## Options
    * receiver (required) - a module that implements `Libmention.Incoming.Receiver`
    * path - the webmentions path in your router. This is helpful when you want to let users visit a status page for their webmention.

  ## Example usage
  ```
  scope "/webmentions" do
    pipe_through(:api)
    forward "/", Libmention.Incoming.ReceiverPlug, receiver: Silbernageldev.WebMentions.Receiver, path: "/webmentions"
  end
  ```
  """
  import Plug.Conn

  @doc false
  def init(opts) do
    if is_nil(GenServer.whereis(Libmention.IncomingSupervisor)) do
      raise """
      libmention is misconfigured - please set the incoming supervisor options in Libmention 
      """
    end

    receiver = Keyword.get(opts, :receiver, nil)
    path = Keyword.get(opts, :path, "/webmentions")

    if receiver == nil do
      raise """
      a receiver module is required to use Libmention.Incoming.ReceiverPlug
      """
    else
      %{receiver: receiver, path: path}
    end
  end

  @doc false
  def call(%{params: %{"source" => source, "target" => target}} = conn, %{
        receiver: receiver,
        path: path
      }) do
    with {:ok, source_uri} <- URI.new(source),
         false <- is_nil(source_uri.scheme),
         {:ok, target_uri} <- URI.new(target),
         {:ok, %Req.Response{status: 200}} <- Req.get(URI.to_string(source_uri)),
         :ok <- receiver.validate(target_uri) do
      id = receiver.queue(source_uri, target_uri)

      conn
      |> Plug.Conn.put_resp_header("Location", "#{path}/#{id}")
      |> Plug.Conn.resp(201, "")
      |> send_resp()
    else
      _ -> send_resp(conn, 400, "invalid request")
    end
  end

  def call(conn, _opts) do
    send_resp(conn, 400, "invalid request")
  end
end
