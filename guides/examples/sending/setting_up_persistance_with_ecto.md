# Setting up Persistence with Ecto

By default `libmention` stores the results of your discovery calls and webmention sending attempts in an `ets` table. When another attempt to send a webmention happens, `libmention` determines whether or not to send another webmention based on the entry in that storage AND if the content has changed or not.

`ets` works great for this purpose if you have zero downtime, but as soon as the server is restarted, the `ets` table is wiped. For this reason, it may make sense to swap the `ets` storage with something more persistent.

Setting up `libmention` to use your current relational DB is pretty easy.

## Create your Ecto Schema

Start by creating you table and schema

```elixir
defmodule MyApp.Webmentions.OutgoingWebmention do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "outgoing_webmentions" do
    field(:source_url, :string)
    field(:target_url, :string)
    field(:endpoint, :string)
    field(:sha, :string)
    field(:status, Ecto.Enum, values: [:sent, :not_found, :failed, :pending])

    timestamps()
  end

  @attrs [:source_url, :target_url, :status, :sha, :endpoint]
  @required [:source_url, :target_url, :status, :sha]

  def changeset(mention \\ %OutgoingWebmention{}, params) do
    mention
    |> cast(params, @attrs)
    |> validate_required(@required)
  end
end
```


## Implement the StorageApi

Libmention provides a simple behaviour for it's storage api, `Libmention.StorageApi`.

Lets implement it.

```elixir
defmodule MyApp.Webmentions.WebmentionStorage do
  @behaviour Libmention.StorageApi

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Webmentions.OutgoingWebmention

  # The entity for these calls looks like:
  #
  # %{
  #   source_url: String.t(),
  #   target_url: String.t(),
  #   endpoint: String.t(),
  #   status: :sent | :not_found | :failed | :pending,
  #   sha: String.t()
  # }

  @impl true
  def save(entity) do
    changeset = Webmention.changeset(entity)
    Repo.insert(changeset)
  end

  @impl true
  def update(entity) do
    existing_mention = get(entity)
    changeset = Webmention.changeset(existing_mention, entity)
    Repo.update(changeset)
  end

  @impl true
  def get(entity) do
    entity
    |> webmention_query()
    |> Repo.one()
  end

  @impl true
  def exists?(entity) do
    entity
    |> webmention_query()
    |> Repo.exists?()
  end

  defp webmention_query(entity) do
    Webmention
    |> where([wm], wm.source_url == ^entity.source_url)
    |> where([wm], wm.target_url == ^entity.target_url)
  end
end
```

## Update your Configuration

The last step is to update your `libmention` config.

```elixir
    libmention_opts = [
        outgoing: [
            ...
            storage: MyApp.Webmentions.WebmentionStorage,
            ...
        ]
    ]

    children = [
        ...
        YourWeb.Endpoint,
        {Libmention.Supervisor, libmention_opts}
    ]
    
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
```

> See [Libmention.Supervisor](https://hexdocs.pm/libmention/Libmention.Supervisor.html#module-options) for all configuration options

## Whats Next?

That's all thee is to storing webmention results. You can use this storage to build a little dashboard if you want web view of your data.
