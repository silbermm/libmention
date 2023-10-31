defmodule Libmention.Incoming.Worker do
  @moduledoc false

  use GenServer, restart: :transient

  alias __MODULE__

  defstruct [:storage, :source, :target, :receiver]

  def start_link(opts) do
    dbg(opts)
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    storage = Keyword.get(opts, :storage)
    source = Keyword.get(opts, :source_url)
    target = Keyword.get(opts, :target_url)
    receiver = Keyword.get(opts, :receiver)
    state = %Worker{storage: storage, source: source, target: target, receiver: receiver}
    {:ok, state, {:continue, :process}}
  end

  @impl true
  def handle_continue(:process, state) do
    dbg("PROCESSING")

    entity = %{
      source_url: URI.to_string(state.source),
      target_url: URI.to_string(state.target),
      direction: :in,
      state: :processed
    }

    _ = state.storage.update(entity)

    {:stop, :normal, state}
  end
end
