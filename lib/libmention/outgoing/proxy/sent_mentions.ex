defmodule Libmention.Outgoing.Proxy.SentMentions do
  @moduledoc false
  alias Libmention.Outgoing.Proxy
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # Get available webmentions
    all = :ets.tab2list(Proxy.proxy_table())
    group = Enum.group_by(all, fn {endpoint, _} -> endpoint end, fn {_, data} -> data end)

    html = ~s"""
    <!DOCTYPE html>
      <html lang="en-US">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width" />
        <title>My test page</title>
      </head>
      <body>
        #{for {key, values} <- group do
          ~s"""
            <details> 
              <summary> #{key} </summary>
              <p>
                #{table_for(values)} 
              </p>
            </details>
          """
        end}
      </body>
    </html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
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
