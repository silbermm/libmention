defmodule Libmention.Incoming.WorkerSupervisor do
  @moduledoc false

  use DynamicSupervisor

  @typep source :: URI.t()
  @typep target :: URI.t()

  def start_link(opts), do: DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    storage = Keyword.get(opts, :storage)

    if storage == Libmention.EtsStorage do
      :ets.new(Libmention.EtsStorage.table_name(), [:public, :named_table])
    end

    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [opts])
  end

  @doc """
  """
  @spec process_webmention(source(), target()) ::
          {:ok, pid()} | :ignore | {:error, term()} | {:ok, pid(), term()}
  def process_webmention(source, target) do
    case DynamicSupervisor.start_child(__MODULE__, Libmention.Incoming.Worker) do
      {:ok, pid} ->
        Libmention.Incoming.Worker.process(pid, source, target)
        {:ok, pid}

      error ->
        error
    end
  end

end
