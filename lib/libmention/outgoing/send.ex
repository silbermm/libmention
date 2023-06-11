defmodule Libmention.Outgoing.Send do
  @moduledoc """
  See [Sending Webmentions](https://www.w3.org/TR/webmention/#sending-webmentions) for the full spec.

  Functions for finding links in an html document, discovering webmention support, and sending webmentions
  from a `source_url` to a `target_url`.
  """
  alias Libmention.HttpApi

  @typep html :: String.t()
  @typep link :: String.t()
  @typep links :: [link()]

  defmodule Error do
    defexception [:message]
  end

  @doc """
  Sends a webmention to `endpoint`.

  `source_url` is the URL of the html page containing a link
  `target_url` is the URL of the page being linked to 

  If the `endpoint supports sending back a location for monitoring
  the queued request, an `{:ok, url}` will be returned, otherwise
  just an `:ok` will be returned.
  """
  @spec send(String.t(), String.t(), String.t(), keyword()) ::
          :ok | {:ok, String.t()} | {:error, String.t()}
  def send(endpoint, source_url, target_url, _opts) do
    case Req.post(endpoint, form: [source: source_url, target: target_url]) do
      {:ok, %{status: 201, headers: _headers}} ->
        {:ok, ""}

      {:ok, %{status: 202, headers: _headers}} ->
        :ok

      {:ok, %{status: status}} ->
        {:error, "unexpected response from #{endpoint}, expected 201 or 202, got #{status}"}

      {:error, err} ->
        {:error, "Unexpected error from #{endpoint} | #{inspect(err)}"}
    end
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
  """
  @spec discover(String.t(), keyword()) :: String.t()
  def discover(target_url, opts \\ []) do
    link_in_headers = head_discover(target_url, opts)
    if link_in_headers != "", do: link_in_headers, else: get_discover(target_url, opts)
  end

  defp head_discover(target_url, _opts) do
    case HttpApi.head(target_url, user_agent: "libmention-Webmention-Discovery") do
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

  defp get_discover(target_url, _opts) do
    case HttpApi.get(target_url, user_agent: "libmention-Webmention-Discovery") do
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
