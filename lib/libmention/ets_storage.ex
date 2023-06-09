defmodule Libmention.EtsStorage do
  @moduledoc false

  @behaviour Libmention.StorageApi

  @impl true
  def save(entity) do
    id = entity.source_url <> entity.target_url
    :ets.insert(table_name(), {id, entity})
    {:ok, entity}
  end

  @impl true
  def update(entity), do: save(entity)

  @impl true
  def get(id) when is_binary(id) do
    [{_, data}] = :ets.lookup(table_name(), id)
    data
  end

  def get(entity) when is_map(entity) do
    id = entity.source_url <> entity.target_url
    [{_, data}] = :ets.lookup(table_name(), id)
    data
  end

  @impl true
  def exists?(entity) do
    id = entity.source_url <> entity.target_url
    res = :ets.lookup(table_name(), id)
    !Enum.empty?(res)
  end

  def table_name, do: :webmentions
end
