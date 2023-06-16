defmodule Libmention.Outgoing.WorkerTest do
  use ExUnit.Case

  alias Libmention.Outgoing.Worker
  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  @default_opts [
    user_agent: "test-libmention"
  ]

  @url "http://localhost/test"

  @good_webmention_url "https://goodwebmention.com"
  @bad_webmention_url "https://badwebmention.com"

  @endpoint "https://goodwebmention.com/webmentions"

  @html """
  <html>
  <body>
    <a href="#{@good_webmention_url}"> Good Webmention </a> 
    <a href="#{@bad_webmention_url}"> Bad Webmention </a> 
  </body>
  """

  describe "start worker and send process html" do
    setup do
      spec = %{
        id: Worker,
        start: {Worker, :start_link, [@default_opts, []]}
      }

      {:ok, pid} = start_supervised(spec)
      %{pid: pid}
    end

    test "sends webmention for valid endpoint", %{pid: pid} do
      expect_webmention_head()
      expect_webmention_get()

      Worker.process(pid, @url, @html)

      assert_receive :done
    end
  end

  defp expect_webmention_head() do
    expect(MockHttp, :head, fn @good_webmention_url, _opts ->
      {:ok,
       %{
         status: 200,
         headers: [
           {"server", "nginx/1.14.0"},
           {"content-type", "text/html; charset=UTF-8"},
           {"connection", "keep-alive"},
           {"cache-control", "no-cache"},
           {"link", @good_webmention_url}
         ]
       }}
    end)

    expect(MockHttp, :head, fn @bad_webmention_url, _opts ->
      {:ok,
       %{
         status: 200,
         headers: [
           {"server", "nginx/1.14.0"},
           {"content-type", "text/html; charset=UTF-8"}
         ]
       }}
    end)
  end

  defp expect_webmention_get() do
    expect(MockHttp, :get, fn @good_webmention_url, _opts ->
      {:ok,
       %{
         status: 200,
         headers: [{"content-type", "text/html; charset=UTF-8"}],
         body: ~s"""
         <!doctype html>
         <html>
           <head>
           <link href="#{@endpoint}" rel="webmention" />
           </head>
           <body>
           <a href="#{@endpoint}" rel="webmention">webmention</a>
           </body>
         </html>
         """
       }}
    end)

    expect(MockHttp, :get, fn @bad_webmention_url, _opts ->
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
  end
end
