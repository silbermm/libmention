defmodule Libmention.StorageApi do
  @moduledoc """
  The behaviour for required for storing a webmention.

  By default `ets` is used, but implementing this behaviour
  and setting your configuration value to that implementation,
  you can use any storage back-end you want.
  """

  @typedoc """
  The shape of the webmention passed to the `c:save/1`, `c:update/1` and `c:exists?/1`
  """
  @type entity :: %{
          source_url: String.t(),
          target_url: String.t(),
          endpoint: String.t(),
          status: :sent | :not_found | :failed | :pending | :processed,
          direction: :in | :out,
          sha: String.t()
        }

  @typep id :: term()

  @doc """
  This is called after a webmention is sent or successfully received.

  ## Receiving a webmention
  This will be called when the target and source have been verified. The
  status will be `:pending` and the direction will be `:in`.

  ## Sending a webmention
  This will be called when the mention is sent. Depending on the result
  of the http call, status will be `sent`, `not_found` or `failed`  and the
  direction will be `:out`
  """
  @callback save(entity()) :: {:ok, term()} | {:error | term()}

  @doc """
  This is called when the content of a webmention (sha) changes for a
  webmention that has already been sent or the status is changing.
  """
  @callback update(entity()) :: {:ok, term()} | {:error | term()}

  @doc """
  Determines if a webmention already exists in the storage.
  """
  @callback exists?(entity()) :: boolean()

  @doc """
  Gets the webmention out of storage
  """
  @callback get(id() | entity()) :: term() | nil

  @doc """
  Return all pending incoming webmentions.
  """
  @callback all_pending_incoming() :: [entity()]
end
