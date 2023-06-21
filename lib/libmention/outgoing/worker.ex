defmodule Libmention.Outgoing.Worker do
  @moduledoc false

  use GenServer, restart: :temporary

  alias __MODULE__
  alias Libmention.Outgoing

  defstruct [:opts, :html, :sha, :source_url, :links, :from_pid, :endpoints]

  def start_link(opts, _), do: GenServer.start_link(__MODULE__, opts)

  @impl true
  def init(opts) do
    opts = Keyword.put_new(opts, :storage, Libmention.EtsStorage)
    state = %Worker{opts: opts}
    {:ok, state}
  end

  def process(pid, source_url, html), do: GenServer.call(pid, {:process, source_url, html})

  @impl true
  def handle_call({:process, source_url, html}, {from_pid, _}, state) do
    sha = hash_content(html)
    state = %{state | html: html, source_url: source_url, from_pid: from_pid, sha: sha}
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
    storage_api = Keyword.get(state.opts, :storage)

    endpoints =
      for link <- state.links, reduce: [] do
        acc ->
          entity = build_entity(state, link)
          exists? = storage_api.exists?(entity)
          dbg entity
          dbg exists?
          handle_existing_or_changed_entity(entity, exists?, state, link, acc)
      end

    state = %{state | endpoints: endpoints}
    {:noreply, state, {:continue, :send_webmentions}}
  end

  def handle_continue(:send_webmentions, %Worker{endpoints: []} = state) do
    send(state.from_pid, :done)
    {:stop, :normal}
  end

  def handle_continue(:send_webmentions, state) do
    storage_api = Keyword.get(state.opts, :storage)

    res =
      for {target_url, endpoint, exists?} <- state.endpoints, reduce: [] do
        acc ->
          entity = build_entity(state, target_url, endpoint: endpoint)

          endpoint
          |> Outgoing.send(state.source_url, target_url, state.opts)
          |> case do
            {:ok, location} ->
              if exists? do
                update_content(storage_api, entity, :sent)
              else
                save_result(storage_api, entity, :sent)
              end

              [location | acc]

            :ok ->
              if exists? do
                update_content(storage_api, entity, :sent)
              else
                save_result(storage_api, entity, :sent)
              end

              acc

            _error ->
              if exists? do
                update_content(storage_api, entity, :failed)
              else
                save_result(storage_api, entity, :failed)
              end

              acc
          end
      end

    send(state.from_pid, {:done, res})
    {:stop, :normal}
  end

  defp handle_existing_or_changed_entity(entity, false, state, link, acc) do
    storage_api = Keyword.get(state.opts, :storage)
    endpoint = Outgoing.discover(link, state.opts)

    if is_nil(endpoint) do
      _ = save_result(storage_api, entity, :not_found)
      acc
    else
      [{link, endpoint, false} | acc]
    end
  end

  defp handle_existing_or_changed_entity(entity, true, state, link, acc) do
    storage_api = Keyword.get(state.opts, :storage)

    # check the sha and see if the content has been updated
    from_storage = storage_api.get(entity)

    if from_storage.sha == state.sha do
      acc
    else
      [{link, from_storage.endpoint, true} | acc]
    end
  end

  defp build_entity(state, link, opts \\ []) do
    status = Keyword.get(opts, :status, :initial)
    endpoint = Keyword.get(opts, :endpoint, nil)

    %{
      source_url: state.source_url,
      target_url: link,
      sha: state.sha,
      endpoint: endpoint,
      status: status
    }
  end

  defp save_result(storage_api, entity, status) do
    entity = Map.put(entity, :status, status)
    storage_api.save(entity)
  end

  defp update_content(storage_api, entity, status) do
    entity = Map.put(entity, :status, status)
    storage_api.update(entity)
  end

  defp hash_content(html), do: :crypto.hash(:sha512, html) |> Base.encode64()
end
