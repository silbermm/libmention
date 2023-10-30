defmodule Libmention.Supervisor do
  @moduledoc """
  Responsible for managing send and receive jobs.

  Put this in your supervision tree to start the processes of sending and/or receiving webmentions.

  ```elixir
  opts = [
    outgoing: [],
    incoming: []
  ]

  children = [
    ...,
    {Libmention.Supervisor, opts}
  ]
  ```

  ## Options
  A keyword list of options is accepted for configuring one or both of
  * incoming webmentions (See "Incoming Opts" section)
  * outgoing webmentions (See "Outgoing Opts" section)

  ### Incoming opts
  To accept webmentions, use the `incoming` key to configure receiving options.

  ```elixir
  incoming: [
    receiver: MyApp.Receiver,
    storage: Libmention.EtsStorage
  ]
  ```
  Options include:
    * storage - Module - The storage module that implements `Libmention.StorageApi`. Defaults to Libmention.EtsStorage. See `Libmention.StorageApi` for more options.
    * receiver - Module - The module that implements `Libmention.Incoming.Receiver`. This is a required option for receiving webmentions. See the `Libmention.Incoming.Receiver` for more options.

  You will also want o add route to your router that forwards traffic to `Libmention.Incoming.ReceiverPlug`.

  ```
  # my_web/router.ex
  scope /webmentions do
    forward "/", Libmention.Incoming.ReceiverPlug, receiver: MyApp.Receiver
  end
  ```

  Finally, you'll need to add a `<link>` or `<a>` element in your html with a rel value of `webmention`
  that points to the above route.
  ```html
  <head>
    <link href="https://myblog.com/webmentions" rel="webmention">
  </head>
  ```

  ### Outgoing opts
  If you desire to send webmentions from your site, an `outgoing` key should be configured which
  takes it's own keyword list of options.
  ```elixir
  outgoing: [
    user_agent: "",
    storage: Libmention.EtsStorage,
    proxy: [
      port: 8082,
      host: "localhost"
    ]
  ]
  ```
  Options include:
    * user_agent - String - Customize the HTTP User Agent used when fetching the target URL. Defaults to "libmention-Webmention-Discovery"
    * storage    - Module - The storage behaviour module to use when sending webmentions. Defaults to Libmention.EtsStorage. See `Libmention.StorageApi` for more options.
    * proxy      - Keyword List - This is useful for local development only. If enabled, it starts a Plug application on the requested port `proxy: [port: 8082]` that all sent webmentions go to and shows a dashboard with their payloads. See `Libmention.Outgoing.Proxy` for a full explanation and other options available.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(args) do
    outgoing_opts = Keyword.get(args, :outgoing, nil)
    incoming_opts = Keyword.get(args, :incoming, nil)

    children = []

    children =
      if outgoing_opts do
        outgoing_opts = Keyword.put_new(outgoing_opts, :storage, Libmention.EtsStorage)
        children ++ [Libmention.OutgoingSupervisor.child_spec(outgoing_opts)]
      else
        children
      end

    children =
      if incoming_opts do
        incoming_opts = Keyword.put_new(incoming_opts, :storage, Libmention.EtsStorage)
        children ++ [Libmention.IncomingSupervisor.child_spec(incoming_opts)]
      else
        children
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Starts a process that parses, validates and sends webmentions.
  """
  def send(url, html), do: Libmention.Outgoing.WorkerSupervisor.process_content(url, html)
end
