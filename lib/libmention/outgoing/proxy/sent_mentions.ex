defmodule Libmention.Outgoing.Proxy.SentMentions do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    table = Keyword.get(conn.assigns.proxy_opts, :webmentions_table)
    discovery_table = Keyword.get(conn.assigns.proxy_opts, :discovery_table)

    # Get available discovery requests
    all_discovery = :ets.tab2list(discovery_table)

    # Get available webmentions
    all = :ets.tab2list(table)

    webmention_group =
      Enum.group_by(all, fn {endpoint, _} -> endpoint end, fn {_, data} -> data end)

    discovery_group =
      Enum.group_by(all_discovery, fn {endpoint, _} -> endpoint end, fn {_, data} -> data end)

    html = ~s"""
    <!DOCTYPE html>
      <html lang="en-US">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width" />
        <title>My test page</title>
      </head>
      <body>
        <h2> Sent Discovery Requests </h2>
        #{discovery_requests(discovery_group)}

        <h2> Sent Webmentions </h2>
        #{webmentions(webmention_group)}
      </body>
    </html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  defp discovery_requests(requests) do
    for {key, values} <- requests do
      ~s"""
        <details> 
          <summary> #{key} </summary>
          <p>
            #{discovery_table(values)} 
          </p>
        </details>
      """
    end
  end

  defp webmentions(group) do
    for {key, values} <- group do
      ~s"""
        <details> 
          <summary> #{key} </summary>
          <p>
            #{table_for(values)} 
          </p>
        </details>
      """
    end
  end

  defp discovery_table(entries) do
    ~s"""
    <table border="1">
      <thead>
        <th> Method </th>
        <th> Timestamp </th>
      </thead>
      <tbody>
        #{for %{method: method, timestamp: timestamp} <- entries do
      ~s"""
      <tr>
        <td> #{method} </td>
        <td> #{timestamp} </td>
      </tr>
      """
    end}
      </tbody>
    </table>
    """
  end

  defp table_for(entries) do
    ~s"""
    <table border="1">
      <thead>
        <th> Source URL </th>
        <th> Target URL </th>
        <th> Timestamp </th>
      </thead>
      <tbody>
        #{for %{source: source, target: target, timestamp: timestamp} <- entries do
      ~s"""
      <tr>
        <td> #{source} </td>
        <td> #{target} </td>
        <td> #{timestamp} </td>
      </tr>
      """
    end}
      </tbody>
    </table>
    """
  end
end
