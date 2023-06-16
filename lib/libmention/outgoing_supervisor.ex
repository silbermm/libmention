defmodule Libmention.OutgoingSupervisor do
  @moduledoc false

  use DynamicSupervisor

  def start_link(opts), do: DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts), do: DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: opts)

  @doc """
  Starts a worker that finds links, discovers webmention endpoints and sends webmentions.
  """
  @spec process_content(String.t(), String.t() | Floki.html_tree()) ::
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
