defmodule Libmention.Outgoing.Worker do
  @moduledoc false

  use GenServer, restart: :temporary

  alias __MODULE__
  alias Libmention.Outgoing

  defstruct [:opts, :html, :source_url, :links, :from_pid, :endpoints]

  def start_link(opts, _) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    state = %Worker{opts: opts}
    {:ok, state}
  end

  def process(pid, source_url, html), do: GenServer.call(pid, {:process, source_url, html})

  @impl true
  def handle_call({:process, source_url, html}, {from_pid, _}, state) do
    state = %{state | html: html, source_url: source_url, from_pid: from_pid}
    {:reply, :processing, state, {:continue, :find_links}}
  end

  @impl true
  def handle_continue(:find_links, state) do
    links = Outgoing.parse(state.html)
    {:noreply, %{state | links: links}, {:continue, :discover}}
  end

  def handle_continue(:discover, %Worker{links: []} = state) do
    # No links to be found
    send(state.from_pid, :done)
    {:stop, :normal}
  end

  def handle_continue(:discover, state) do
    endpoints =
      for link <- state.links, reduce: [] do
        acc ->
          # should we send a discover message?
          # only if we look in storage and determine that the
          # webmention needs to be sent based:
          #   * the link
          #   * the source
          #   * the content


          endpoint = Outgoing.discover(link, state.opts)
          if endpoint == nil, do: acc, else: [{link, endpoint} | acc]
      end

    state = %{state | endpoints: endpoints}

    {:noreply, state, {:continue, :send_webmentions}}
  end

  def handle_continue(:send_webmentions, %Worker{endpoints: []} = state) do
    send(state.from_pid, :done)
    {:stop, :normal}
  end

  def handle_continue(:send_webmentions, state) do
    res = for {target_url, endpoint} <- state.endpoints, reduce: [] do
      acc ->
        endpoint
        |> Outgoing.send(state.source_url, target_url, state.opts)
        |> case do
          {:ok, location} -> [location | acc]
          _ -> acc
        end
    end

    send(state.from_pid, {:done, res})
    {:stop, :normal}
  end
end
