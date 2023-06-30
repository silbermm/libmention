# Using with NimblePublisher

[NimblePublisher](https://hexdocs.pm/nimble_publisher/NimblePublisher.html) is a library that uses the filesystem for storage and builds content at compile-time.

When used with [Phoenix](https://www.phoenixframework.org/), it offers a powerful Markdown based platform for building personal websites and blogs.

## Start with NimblePublisher

You can follow along in the [example from the docs](https://hexdocs.pm/nimble_publisher/NimblePublisher.html#module-examples) to get a simple site up and running.

## Add some links to your post(s)

The example blog post from the link above needs a link, for testing our webmention sending:
```elixir
# /posts/2020/04-17-hello-world.md
%{
  title: "Hello world!",
  author: "José Valim",
  tags: ~w(hello),
  description: "Let's learn how to say hello world"
}
---
This is the post.

This is a [link to the webmention testing site](https://webmention.rocks/test/1)

```

With that in place, lets configure `libmention`.

## Configure libmention

Once the example is up and running, you'll want to add `libmention` to your supervision tree.

Start by defining your options
```elixir
libmention_opts = [
    outgoing: [
        proxy: [port: 8082], # only for local dev
        user_agent: "mywebsite-libmention"
    ]
]
```
> See [Libmention.Supervisor](https://hexdocs.pm/libmention/Libmention.Supervisor.html#module-options) for all configuration options

Now add `libmention` AFTER the web server in your supervision tree

```elixir
    children = [
        ...
        YourWeb.Endpoint,
        {Libmention.Supervisor, libmention_opts}
    ]

    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
```

## Send Webmentions

We need to tell `libmention` about our posts, lets create a very simple process.

```elixir
defmodule MyApp.WebMentionSender do
  use GenServer, restart: :temporary

  def start_link(), do: GenServer.start_link(__MODULE__, :ok)

  @impl true
  def init(:ok) do
    pages = MyApp.Blog.all_posts()
    {:ok, %{pages: pages, done: []}, {:continue, :send}}
  end

  @impl true
  def handle_continue(:send, state) do
    for page <- state.pages do
      source_url = Routes.blog_path(Endpoint, :show, page.id)
      Libmention.Supervisor.send(source_url, page.body)
    end

    {:noreply, state}
  end

  # When  the `send/2` function is done, a message will be sent
  # back to the parent process (this process) of :done or {:done, queue_url}
  @impl true
  def handle_info(:done, state) do
    state = %{state | done: [:done | state.done]}
    if Enum.count(state.done) == Enum.count(state.pages) do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:done, url}, state) do
    state = %{state | done: [{:done, url} | state.done]}

    if Enum.count(state.done) == Enum.count(state.pages) do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end
end
```

Great, now update the supervision tree to include this process

```elixir
    children = [
        ...
        YourWeb.Endpoint,
        {Libmention.Supervisor, libmention_opts},
        MyApp.WebmentionSender
    ]
```

Start up your server and browse to [http://localhost:8082/sent](http://localhost:8082/sent).

Since we are running in `dev` mode with the [proxy](https://hexdocs.pm/libmention/Libmention.Outgoing.Proxy.html#content) active, our webmention didn't actually get sent anywhere. Instead, the proxy shows what _would_ have been sent in production mode.

To test this out fully, you'll need to deploy to production and remove the proxy config for the `prod` build.

### Whats next?

The previous configuration will work, but when the server is stopped and restarted, it will send your webmentions all over again. 

This is because we are storing the results of your webmentions in an `ets` table by default. To persist this across restarts, you'll want to look at the guide on getting the persistence layer to work with [Ecto](https://hexdocs.pm/ecto/Ecto.html).
