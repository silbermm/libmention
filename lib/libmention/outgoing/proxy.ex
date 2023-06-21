defmodule Libmention.Outgoing.Proxy do
  @moduledoc """
  A proxy is available for local development purposes.

  When the proxy is enabled, all outgoing http requests are routed to it.
  This provides a way to test your outgoing webmentions locally since they
  will always fail when running on a localhost.

  The reason they will fail is because the server receiving the webmention
  is, according to the spec, required to query the sender (in this case localhost)
  and validate the url that was sent. In the case of local development, this will fail
  and you won't get a good idea if you are sending the correct payload.

  The proxy also makes available a small web-based dashboard where you can inspect
  the webmentions you sent including their payload.
  """
  use Supervisor

  @default_port 8082

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(args) do
    port = Keyword.get(args, :port, @default_port)

    children = [
      {Plug.Cowboy,
       scheme: :http, plug: Libmention.Outgoing.Proxy.Router, options: [port: port]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
