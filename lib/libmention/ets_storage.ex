defmodule Libmention.EtsStorage do
  @moduledoc false

  @behaviour Libmention.StorageApi

  @impl true
  def save(entity) do
    {:ok, entity}
  end

  @impl true
  def update(_id, entity) do
    {:ok, entity}
  end

  @impl true
  def get(id) when is_binary(id) do
    %{}
  end

  def get(entity) when is_map(entity) do
    nil
  end

  @impl true
  def exists?(_entity) do
    true
  end

  def table_name, do: :webmentions
end
