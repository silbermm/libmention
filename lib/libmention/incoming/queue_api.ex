defmodule Libmention.Incoming.QueueApi do
  @moduledoc """

  """

  @type source :: String.t()
  @type target :: String.t()

  @doc """

  """
  @callback queue(source(), target()) :: :ok

end
