defmodule Libmention.Incoming.Worker do
  @moduledoc false

  use GenServer, restart: :temporary 
  alias __MODULE__

  defstruct [:opts, :source, :target]

  def start_link(opts, _), do: GenServer.start_link(__MODULE__, opts)

  @impl true
  def init(opts) do
    opts = Keyword.put_new(opts, :storage, Libmention.EtsStorage)
    state = %Worker{opts: opts}
    {:ok, state}
  end

  def process(pid, source, target), do: GenServer.call(pid, {:process, source, target})

  @impl true
  def handle_call({:process, source, target}, {_from_pid, _}, state) do
    state = %{state | source: source, target: target}
    {:reply, :processing, state}
  end
end
