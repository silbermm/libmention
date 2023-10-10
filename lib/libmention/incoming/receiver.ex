defmodule Libmention.Incoming.Receiver do
  @moduledoc """
  Receiving Webmentions requires information about the system that is
  impossible to know for this library. This module exists to fill in the gaps.

  ## What needs to be implemented
  ### Target URL Validation
  A webmention sends a `source_url` and a `target_url` to the server.
  The `target_url` is the url of the content that is being mentioned.
  `Libmention` uses the `c:validate/1` function to determine the validity
  of the target URL.

  If using NimblePublisher with Phoenix, you can parse the path of the URI
  to get post name with may serve as the id, build a Phoenix route and compare the URLs.

  #### Example
  ```elixir
  defmodule MyContentValidator do
    @behaviour Libmention.Incoming.ContentValidatorApi

    @impl true
    def validate(url) do
      post_id =
        url.path
        |> String.split("/")
        |> Enum.reverse()
        |> List.at(0)

      actual_url_for_post = MyAppWeb.Helpers.blog_url(MyApp.Endpoint, :show, post_id) 
      if actual_url_for_post == URL.to_string(url), do: :ok, else: :not_found
    end
  end
  ```

  ### Publisher


  """

  @doc """
  Validate takes a URI struct that is the target url from the webmention.

  Return values should be one of:
  * :ok
  * :not_found
  * :not_supported
  """
  @callback validate(URI.t()) :: :ok | :not_found | :not_supported

  @typep source :: URI.t()
  @typep target :: URI.t()

  @doc """

  """
  @callback publish(source(), target()) :: :ok

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour __MODULE__ 

      @impl true
      def publish(source, target) do
        
      end

      defoverridable publish: 2

    end
  end

end
