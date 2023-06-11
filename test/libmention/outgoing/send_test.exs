defmodule Libmention.Outgoing.SendTest do
  use ExUnit.Case
  import Mox
  alias Libmention.Outgoing.Send

  setup do
    %{
      link: "https://webmention.example/some/post",
      webmention_link: "https://webmention.example/webmention/endpoint",
      relative_webmention_link: "/with/relative/path",
    }
  end

  describe "when parsing a document for links" do
    setup :generate_html

    test "then a plain html string is parsed and links are found", %{html: html, link: link} do
      assert [^link] = Send.parse(html)
    end

    test "then a floki tree is parsed and links are found", %{html: html, link: link} do
      {:ok, tree} = Floki.parse_document(html)
      assert [^link] = Send.parse(tree)
    end
  end

  describe "when discovering target url webmention endpoint" do
    setup :generate_html_link_in_head

    test "then a link can be found in a HEAD request", %{
      link: link,
      webmention_link: webmention_link
    } do
      webmention_header = ~s[<#{webmention_link}>; rel="webmention"]

      expect(MockHttp, :head, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           headers: [
             {"server", "nginx/1.14.0"},
             {"content-type", "text/html; charset=UTF-8"},
             {"connection", "keep-alive"},
             {"cache-control", "no-cache"},
             {"link", webmention_header}
           ]
         }}
      end)

      assert ^webmention_link = Send.discover(link)
    end

    test "then if link not in head request link can be found in a GET request - html head", %{
      link: link,
      html: html,
      webmention_link: webmention_link
    } do
      expect(MockHttp, :head, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           headers: [{"content-type", "text/html; charset=UTF-8"}]
         }}
      end)

      expect(MockHttp, :get, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           headers: [{"content-type", "text/html; charset=UTF-8"}],
           body: html
         }}
      end)

      assert ^webmention_link = Send.discover(link)
    end
  end

  describe "when discovering target url webmention endpoint and link is in body" do
    setup :generate_html_link_in_body

    test "then link can be found in GET request", %{
      link: link,
      html: html,
      webmention_link: webmention_link
    } do
      expect(MockHttp, :head, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           headers: [{"content-type", "text/html; charset=UTF-8"}]
         }}
      end)

      expect(MockHttp, :get, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           headers: [{"content-type", "text/html; charset=UTF-8"}],
           body: html
         }}
      end)

      assert ^webmention_link = Send.discover(link)
    end
  end

  describe "when discovering target url webmention endpoint with relative link" do
    setup :generate_html_relative_link_in_head

    test "then if link not in head request, relative link can be found in a GET request - html head", %{
      link: link,
      html: html,
      relative_webmention_link: relative_link
    } do
      expect(MockHttp, :head, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           headers: [{"content-type", "text/html; charset=UTF-8"}]
         }}
      end)

      expect(MockHttp, :get, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           headers: [{"content-type", "text/html; charset=UTF-8"}],
           body: html
         }}
      end)

      with_relative = link <> relative_link
      assert ^with_relative = Send.discover(link)
    end
  end

  defp generate_html(%{link: link}) do
    html = ~s"""
    <!doctype html>
    <html>
      <body>
        <a href="#{link}">This is a great post</a>
      </body>
    </html>
    """

    %{html: html}
  end

  defp generate_html_link_in_head(%{webmention_link: webmention_link}) do
    html = ~s"""
    <!doctype html>
    <html>
      <head>
      <link href="#{webmention_link}" rel="webmention" />
      </head>
      <body>
      <a href="#{webmention_link}" rel="webmention">webmention</a>
      </body>
    </html>
    """

    %{html: html}
  end

  defp generate_html_relative_link_in_head(%{relative_webmention_link: webmention_link}) do
    html = ~s"""
    <!doctype html>
    <html>
      <head>
      <link href="#{webmention_link}" rel="webmention" />
      </head>
      <body>
      <a href="#{webmention_link}" rel="webmention">webmention</a>
      </body>
    </html>
    """

    %{html: html}
  end

  defp generate_html_link_in_body(%{webmention_link: webmention_link}) do
    html = ~s"""
    <!doctype html>
    <html>
      <head>
      </head>
      <body>
      <a href="#{webmention_link}" rel="webmention">webmention</a>
      </body>
    </html>
    """

    %{html: html}
  end
end
