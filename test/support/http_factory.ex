defmodule Libmention.HttpFactory do
  @moduledoc false
  import Mox

  def expect_valid_get_request(%{good_webmention_url: good_webmention_url, endpoint: endpoint}) do
    expect(MockHttp, :get, fn ^good_webmention_url, _opts ->
      {:ok,
       %{
         status: 200,
         headers: [{"content-type", "text/html; charset=UTF-8"}],
         body: ~s"""
         <!doctype html>
         <html>
           <head>
           <link href="#{endpoint}" rel="webmention" />
           </head>
           <body>
           <a href="#{endpoint}" rel="webmention">webmention</a>
           </body>
         </html>
         """
       }}
    end)

    :ok
  end

  def expect_valid_head_request(%{good_webmention_url: good_webmention_url, endpoint: endpoint}) do
    webmention_header = ~s[<#{endpoint}>; rel="webmention"]

    expect(MockHttp, :head, fn ^good_webmention_url, _opts ->
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

    :ok
  end

  def expect_invalid_get_request(_) do
    expect(MockHttp, :get, fn _, _opts ->
      {:ok,
       %{
         status: 200,
         headers: [{"content-type", "text/html; charset=UTF-8"}],
         body: ~s"""
         <!doctype html>
         <html>
           <head>
           </head>
           <body>
           </body>
         </html>
         """
       }}
    end)

    :ok
  end

  def expect_invalid_head_request(_) do
    expect(MockHttp, :head, fn _url, _opts ->
      {:ok,
       %{
         status: 200,
         headers: [
           {"server", "nginx/1.14.0"},
           {"content-type", "text/html; charset=UTF-8"}
         ]
       }}
    end)

    :ok
  end

  def expect_valid_post_request(%{endpoint: endpoint}) do
    expect(MockHttp, :post, fn ^endpoint, _opts ->
      {:ok,
       %{
         status: 201,
         headers: [
           {"content-type", "text/html; charset=UTF-8"},
           {"location", "#{endpoint}/queue"}
         ]
       }}
    end)

    :ok
  end

  def expect_invalid_post_request(%{endpoint: endpoint}) do
    expect(MockHttp, :post, fn ^endpoint, _opts ->
      {:ok,
       %{
         status: 400,
         headers: [
           {"content-type", "text/html; charset=UTF-8"},
           {"location", "#{endpoint}/queue"}
         ]
       }}
    end)

    :ok
  end
end
