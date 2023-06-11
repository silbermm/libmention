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
  ```

  ## Options
  A keyword list of options is accepted for configuring one or both of
  * incoming webmentions (See "Incoming Opts" section)
  * outgoing webmentions (See "Outgoing Opts" section)

  ### Incoming opts


  ### Outgoing opts
  If you desire to send webmentions from your site, an `outgoing` key should be configured which
  takes it's own keyword list of options.
  ```elixir
  outgoing: [
    user_agent: ""
  ]
  ```
  Options include:
    * user_agent - customize the HTTP User Agent used when fetching the target URL. Defaults to "libmention-Webmention-Discovery"
  """

  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(args) do
    outgoing_opts = Keyword.get(args, :outgoing, nil)

    children = []

    children =
      if outgoing_opts do
        children ++ [Libmention.OutgoingSupervisor.child_spec(outgoing_opts)]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
