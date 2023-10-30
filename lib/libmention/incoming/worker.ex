defmodule Libmention.Incoming.Worker do
  @moduledoc false

  use GenServer, restart: :transient

  alias __MODULE__

  defstruct [:opts, :source, :target, :receiver]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    opts = Keyword.put_new(opts, :storage, Libmention.EtsStorage)
    state = %Worker{opts: opts}
    {:ok, state}
  end
end
