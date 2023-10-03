defmodule Libmention.Incoming do
  @moduledoc """
  Functions for dealing with incoming webmentions.

  See [Receiving Webmentions](https://www.w3.org/TR/webmention/#receiving-webmentions) for the full spec.
  """

  defmodule Error do
    defexception [:message]
  end
  
end
