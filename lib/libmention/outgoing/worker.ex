defmodule Libmention.Outgoing.Worker do
  @moduledoc false

  use GenServer, restart: :temporary

  alias __MODULE__
  alias Libmention.Outgoing

  defstruct [:opts, :html, :source_url, :links, :from_pid]

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
    send(state.from_pid, :done)
    {:stop, :normal}
  end

  def handle_continue(:discover, state) do
    for link <- state.links do
      Outgoing.discover(link)
    end

    send(state.from_pid, :done)
    {:noreply, state}
  end
end
