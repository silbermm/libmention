defmodule Libmention.EtsStorage do
  @moduledoc false

  @behaviour Libmention.StorageApi

  @impl true
  def save(entity) do
    id = entity.source_url <> entity.target_url
    :ets.insert(table_name(), {id, entity})
  end

  @impl true
  def update(entity), do: save(entity)

  @impl true
  def get(id) when is_binary(id) do
    %{}
  end

  def get(entity) when is_map(entity) do
    id = entity.source_url <> entity.target_url
    [{_, data}] = :ets.lookup(table_name(), id)
    data
  end

  @impl true
  def exists?(entity) do
    match = [
      {{:_, :"$1"},
       [
         {:andalso, {:==, {:map_get, :source_url, :"$1"}, entity.source_url},
          {:==, {:map_get, :target_url, :"$1"}, entity.target_url}}
       ], [:"$1"]}
    ]

    exists = :ets.lookup(table_name(), match)
    !Enum.empty?(exists)
  end

  def table_name, do: :webmentions
end
