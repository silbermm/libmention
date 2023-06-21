defmodule Libmention.Outgoing.WorkerSupervisor do
  @moduledoc false

  use DynamicSupervisor

  @typep url :: String.t()
  @typep html :: String.t() | Floki.html_tree()

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
  Starts a worker that finds links, discovers webmention endpoints and sends webmentions.
  """
  @spec process_content(url(), html()) ::
          {:ok, pid()} | :ignore | {:error, term()} | {:ok, pid(), term()}
  def process_content(url, html) do
    case DynamicSupervisor.start_child(__MODULE__, Libmention.Outgoing.Worker) do
      {:ok, pid} ->
        Libmention.Outgoing.Worker.process(pid, url, html)
        {:ok, pid}

      error ->
        error
    end
  end
end
