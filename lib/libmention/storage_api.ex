defmodule Libmention.StorageApi do
  @moduledoc """
  The behaviour for required for storing a webmention.

  By default `ets` is used, but implementing this behaviour
  and setting your configuration value to that implementation,
  you can use any storage backend you want.
  """
  
  @typedoc """
  The shape of the webmention passed to the save/update/exists? calls
  """
  @type entity :: %{
    source_url: String.t(),
    target_url: String.t(),
    endpoint: String.t(),
    status: :sent | :not_found | :failed | :pending,
    sha: String.t()
  }

  @typep id :: term()
  
  @doc """
  This is called after a webmention is sent.

  Saving the webmention result in storage means that we can make better
  decisions about if we want to send another webmention or not.
  """
  @callback save(entity()) :: {:ok, term()} | {:error | term()} 

  @doc """
  This is called when the content of a webmention (sha) changes and we've
  already and we sent another one.
  """
  @callback update(id(), entity()) :: {:ok, term()} | {:error | term()} 

  @doc """

  """
  @callback exists?(entity()) :: boolean()

  @doc """

  """
  @callback get(id() | entity()) :: term() | nil
end
