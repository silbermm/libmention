defmodule Libmention.Outgoing do
  @moduledoc """
  See [Sending Webmentions](https://www.w3.org/TR/webmention/#sending-webmentions) for the full spec.

  Functions for finding links in an html document, discovering webmention support, and sending webmentions
  from a `source_url` to a `target_url`.
  """
  alias Libmention.HttpApi

  @typep html :: String.t()
  @typep link :: String.t()
  @typep links :: [link()]

  @default_user_agent "libmention-Webmention-Discovery"

  defmodule Error do
    defexception [:message]
  end

  @doc """
  Sends a webmention to `endpoint`.

  `source_url` is the URL of the html page containing a link
  `target_url` is the URL of the page being linked to 

  If the endpoint supports sending back a location for monitoring
  the queued request, an `{:ok, url}` will be returned, otherwise
  just an `:ok` will be returned.

  ### Options
  * user_agent - defaults to `#{@default_user_agent}`
  * proxy      - useful when `Libmention.Outgoing.Proxy` is configured
  """
  @spec send(String.t(), String.t(), String.t(), keyword()) ::
          :ok | {:ok, String.t()} | {:error, String.t()}
  def send(endpoint, source_url, target_url, opts \\ []) do
    user_agent = Keyword.get(opts, :user_agent, @default_user_agent)
    proxy = Keyword.get(opts, :proxy, nil)

    if proxy do
      port = Keyword.get(proxy, :port, 8082)
      HttpApi.post("http://localhost:#{port}/webmentions?proxy_for=#{endpoint}",
        form: [source: source_url, target: target_url],
        user_agent: user_agent
      )
      :ok
    else
      case HttpApi.post(endpoint,
             form: [source: source_url, target: target_url],
             user_agent: user_agent
           ) do
        {:ok, %{status: 201, headers: headers}} ->
          location = find_location_header(headers)
          {:ok, location}

        {:ok, %{status: 202}} ->
          :ok

        {:ok, %{status: status}} ->
          {:error, "unexpected response from #{endpoint}, expected 201 or 202, got #{status}"}

        {:error, err} ->
          {:error, "Unexpected error from #{endpoint} | #{inspect(err)}"}
      end
    end
  end

  defp find_location_header(headers) do
    Enum.reduce(headers, "", fn
      {"location", link}, _acc -> link
      _, acc -> acc
    end)
  end

  @doc """
  Find available links in an html document.

  This is typically used to find links in your post or other html document
  that may need Webmentions sent.
  """
  @spec parse(html() | Floki.html_tree()) :: links()
  def parse(html) when is_binary(html) do
    case Floki.parse_document(html) do
      {:ok, parsed} -> parse(parsed)
      {:error, reason} -> raise Error, "unable to parse html #{inspect(reason)}"
    end
  end

  def parse(html_tree) do
    html_tree
    |> Floki.find(~S{a[href^="https"]})
    |> Enum.flat_map(fn {_, links, _} -> Enum.map(links, &find_hrefs/1) end)
    |> Enum.reject(&is_nil(&1))
    |> Enum.uniq()
  end

  defp find_hrefs({"href", link}), do: link
  defp find_hrefs(_), do: nil

  @doc """
  Fetchs the URL and checks for an HTTP Link header with a rel value of webmention.

  Initially make an HTTP HEAD request to check for the Link header before making a GET request.

  When making a GET request, if the content type of the document is HTML, looks for an HTML <link> and <a> element with a rel value of webmention. If more than one of these is present, the first HTTP Link header takes precedence, followed by the first <link> or <a> element in document order.

  Returns the Webmention link found at the target url.

  ### Options
  * user_agent - defaults to `#{@default_user_agent}`
  """
  @spec discover(String.t(), keyword()) :: String.t() | nil
  def discover(target_url, opts \\ []) do
    link_in_headers = head_discover(target_url, opts)
    if link_in_headers != "", do: link_in_headers, else: get_discover(target_url, opts)
  end

  defp head_discover(target_url, opts) do
    user_agent = Keyword.get(opts, :user_agent, @default_user_agent)

    case HttpApi.head(target_url, user_agent: user_agent) do
      {:ok, %{status: 200, headers: [_ | _] = headers}} ->
        Enum.reduce(headers, "", fn
          {"link", link}, acc -> find_rel(link, acc)
          _, acc -> acc
        end)

      _res ->
        ""
    end
  end

  defp find_rel(link_header, acc) do
    case Regex.run(~r/<([[:alnum:][:punct:]]+)>;+[[:space:]]rel="webmention"/, link_header,
           capture: :all_but_first
         ) do
      [match] -> match
      _ -> acc
    end
  end

  defp get_discover(target_url, opts) do
    user_agent = Keyword.get(opts, :user_agent, @default_user_agent)

    case HttpApi.get(target_url, user_agent: user_agent) do
      {:ok, %{status: 200, headers: _headers, body: body}} ->
        find_webmention_links(body, target_url)

      {:ok, %{status: _status, body: body}} ->
        find_webmention_links(body, target_url)

      {:error, err} ->
        raise Error, "Unable to complete discovery at #{target_url} | #{inspect(err)}"
    end
  end

  defp find_webmention_links(body, orig_link) do
    case Floki.parse_document(body) do
      {:ok, document} ->
        links_with_webmention = Floki.find(document, ~S{link[rel="webmention"]})
        a_with_webmention = Floki.find(document, ~S{a[rel="webmention"]})

        links_with_webmention
        |> Enum.concat(a_with_webmention)
        |> Floki.attribute("href")
        |> Enum.map(fn
          "/" <> rest -> orig_link <> "/" <> rest
          link -> link
        end)
        |> List.first()

      {:error, reason} ->
        raise Error, "Unable to parse #{orig_link} for discovery | #{inspect(reason)}"
    end
  end
end
