defmodule Libmention.HttpApi do
  @moduledoc false

  @callback head(String.t(), keyword()) :: {:ok, map()} | {:error, map()}
  @callback get(String.t(), keyword()) :: {:ok, map()} | {:error, map()}


  defp impl, do: Application.get_env(:libmention, :http_api, Req)
  def head(url, opts), do: impl().head(url, opts)
  def get(url, opts), do: impl().get(url, opts) 
end
