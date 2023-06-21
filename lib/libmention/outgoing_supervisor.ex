defmodule Libmention.OutgoingSupervisor do
  @moduledoc false

  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(args) do
    proxy = Keyword.get(args, :proxy)

    children =
      if proxy do
        [Libmention.Outgoing.Proxy.child_spec(proxy)]
      else
        []
      end

    children = children ++ [Libmention.Outgoing.WorkerSupervisor.child_spec(args)]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
