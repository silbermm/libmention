defmodule Libmention.Incoming.Receiver do
  @moduledoc """
  Receiving Webmentions requires information about the system that is
  impossible to know for this library. This module exists to fill in the gaps.

  ## What needs to be implemented
  ### validate/1
  A webmention sends a `source_url` and a `target_url` to the server.
  The `target_url` is the url of the content that is being mentioned.
  `Libmention` uses the `c:validate/1` function to determine the validity
  of the target URL.

  If using NimblePublisher with Phoenix, you can parse the path of the URI
  to get post name with may serve as the id, build a Phoenix route and compare the URLs.

  ### handle_processed/3
  *Optional*

  Once the webmention is processed, this callback is called with then
  original source and target urls.

  ## Options
    * timeout - defaults to 1_000

      By default, one webmention request is processed from the queue every
      second. A timeout can be passed to slow or speed up processing the 
      queue.

  ## Example
  ```elixir
  defmodule MyApp.WebmentionReceiver do
    use Libmention.Incoming.Receiver, timeout: 100

    require Logger

    @impl true
    def validate(url) do
      post_id =
        url.path
        |> String.split("/")
        |> Enum.reverse()
        |> List.at(0)

      actual_url_for_post = MyAppWeb.Helpers.blog_url(MyApp.Endpoint, :show, post_id) 
      if actual_url_for_post == URL.to_string(url), do: :ok, else: :not_found
    end

    @impl true
    def handle_processed(id, source_url, target_url) do
      Logger.info("done!")
    end
  end
  ```
  """

  @type target_url :: URI.t()
  @type source_url :: URI.t()

  @doc """
  Queue up a webmention request

  Takes the module that implements the Receiver behaviour
  """
  @spec queue(module, target_url(), source_url()) :: number()
  def queue(module, target_url, source_url) do
    GenServer.call(module, {:queue, target_url, source_url})
  end

  @doc """
  Validate takes a URI struct that is the target URL from the webmention.

  The implementation needs to validate that the given URL accepts webmentions
  and then return one of:
  * :ok
  * :not_found
  * :not_supported
  """
  @callback validate(target_url()) :: :ok | :not_found | :not_supported

  @doc """
  Called once a webmention request has been processed.

  This gives the implementer an option to react to a successfully
  processed webmention request.
  """
  @callback handle_processed(number(), source_url(), target_url()) :: :ok

  @doc false
  defmacro __using__(opts) do
    timeout = Keyword.get(opts, :timeout, 1_000)

    quote do
      require unquote(__MODULE__)
      require Logger

      import unquote(__MODULE__)

      @behaviour Libmention.Incoming.Receiver
      @timeout unquote(timeout)

      use GenServer

      def start_link(opts) do
        # get opts like how how often to run
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl GenServer
      def init(opts) do
        # default to a queue, but allow for options
        # to store in the DB
        timeout = Keyword.get(opts, :timeout, @timeout)
        state = %{queue: :queue.new(), opts: %{timeout: timeout}}
        {:ok, state, {:continue, :loop}}
      end

      @impl Libmention.Incoming.Receiver
      def validate(url), do: :not_supported

      @impl Libmention.Incoming.Receiver
      def handle_processed(id, source_url, target_url) do
        Logger.debug(
          "Successfully processed webmention request for source #{inspect(source_url)} and target #{inspect(target_url)}"
        )
      end

      @doc false
      def queue(target_url, source_url) do
        GenServer.call(__MODULE__, {:queue, target_url, source_url})
      end

      @impl GenServer
      def handle_continue(:loop, state), do: loop(state)

      @impl GenServer
      def handle_info(:process_queue, %{queue: queue} = state) do
        # process the queue
        # take from the front of the queue
        updated_queue =
          case :queue.out(queue) do
            {{:value, webmention_data}, updated_queue} ->
              _ =
                Libmention.Incoming.WorkerSupervisor.process_webmention(
                  webmention_data.source_url,
                  webmention_data.target_url,
                  __MODULE__
                )

              updated_queue

            {:empty, updated_queue} ->
              updated_queue
          end
        dbg updated_queue

        state = %{state | queue: updated_queue}
        loop(state)
      end

      def handle_info({:processed, id, source, target}, state) do
        _ = handle_processed(id, source, target)
        {:no_reply, state}
      end

      @impl GenServer
      def handle_call({:queue, target_url, source_url}, _ = from, %{queue: queue} = state) do
        id = :erlang.phash2(URI.to_string(target_url) <> URI.to_string(source_url))
        queue = :queue.in(%{id: id, target_url: target_url, source_url: source_url}, queue)
        state = %{state | queue: queue}
        {:reply, id, state}
      end

      defp loop(state) do
        timeout = state.opts.timeout
        Process.send_after(__MODULE__, :process_queue, timeout)
        {:noreply, state}
      end

      defoverridable validate: 1, handle_processed: 3
    end
  end
end
