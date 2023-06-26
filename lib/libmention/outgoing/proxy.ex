defmodule Libmention.Outgoing.Proxy do
  @default_port 8082

  @moduledoc """
  A proxy is available for local development purposes.

  When the proxy is enabled, outgoing http requests are routed to it.
  This provides a way to test your outgoing webmentions locally since they
  will always fail when running on a localhost.

  The reason they will fail is because the server receiving the webmention
  is, according to the spec, required to query the sender (in this case localhost)
  and validate the url that was sent. In the case of local development, this will fail
  and you won't get a good idea if you are sending the correct payload.

  The proxy, when configured for localhost, makes available a small web-based dashboard where you can inspect
  the discovery calls and the webmentions that were sent.

  By default, the proxy exposes the web interface at [http://localhost:8082/sent](http://localhost:8082/sent),
  but is configurable via the options passed in.

  ## Options
    * `port`      - defaults to #{@default_port}
    * `host`      - defaults to `http://localhost` (See "Optional Host" section for other options)
    * `patterns`  - this can be used to fine tune which http traffic gets routed to the proxy and even what is returned (See "Patterns" section for a full explanation)

  ### Optional Host
  You may want to run your own proxy in development/staging that handles your
  traffic and contains custom rules for different links.

  This option provides a way to configure which host your webmention traffic is sent to.

  Your Web Server will receive traffic at the following methods/routes:
    * `HEAD /discover` _optional_
      * Looks for a Link response header similar to `Link: <http://aaronpk.example/webmention-endpoint>; rel="webmention"`
    * `GET /discover`
      * Looks for html with a `<link rel="webmention" href="" />` in the head OR
      * Looks for html with a `<a rel="webmention" href="" />` in the body
    * `POST /webmention`
      * sends a body that is of type `application/x-www-form-urlencoded` with the source and target

  All of these calls will include a query param of `proxy_for` which will be the endpoint that would have
  been used without the proxy.

  ### Patterns
  _coming soon_
  """
  use Supervisor

  @doc false
  def webmentions_table, do: :proxy_webmentions

  @doc false
  def discovery_table, do: :proxy_discovery

  @doc false
  def start_link(init_arg) do
    :ets.new(webmentions_table(), [:public, :duplicate_bag, :named_table])
    :ets.new(discovery_table(), [:public, :duplicate_bag, :named_table])
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc false
  @impl true
  def init(args) do
    port = Keyword.get(args, :port, @default_port)
    host = Keyword.get(args, :host, "http://localhost")

    children =
      if host == "http://localhost" do
        [
          {Plug.Cowboy,
           scheme: :http,
           plug:
             {Libmention.Outgoing.Proxy.Router,
              webmentions_table: webmentions_table(), discovery_table: discovery_table()},
           options: [port: port]}
        ]
      else
        []
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
