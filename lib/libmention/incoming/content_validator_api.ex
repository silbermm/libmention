defmodule Libmention.Incoming.ContentValidatorApi do
  @moduledoc """
  Content Validation API

  A content_validator is a tool to verify that the target_url in the
  incoming webmention is a resource that exists and accepts webmentions.
  """

  @doc """
  Validate takes a URI struct that is the target url from the webmention.

  Return values should be one of:
  * :ok
  * :not_found
  * :not_supported
  """
  @callback validate(URI.t()) :: :ok | :not_found | :not_supported
end
