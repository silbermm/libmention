defmodule Libmention.Case do
  @moduledoc false
  use ExUnit.CaseTemplate
  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    url = "http://localhost/test"

    good_webmention_url = "https://goodwebmention.com"
    bad_webmention_url = "https://badwebmention.com"
    endpoint = "https://goodwebmention.com/webmentions"

    html = """
    <html>
    <body>
      <a href="#{good_webmention_url}"> Good Webmention </a> 
      <a href="#{bad_webmention_url}"> Bad Webmention </a> 
    </body>
    """

    updated_html = """
    <html>
    <body>
      <a href="#{good_webmention_url}"> Good Webmention </a> 
      <a href="#{bad_webmention_url}"> Bad Webmention </a> 
      <h2> updated </h2>
    </body>
    """

    %{
      url: url,
      good_webmention_url: good_webmention_url,
      bad_webmention_url: bad_webmention_url,
      endpoint: endpoint,
      html: html,
      updated_html: updated_html
    }
  end
end
