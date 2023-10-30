defmodule Libmention.IncomingSupervisor do
  @moduledoc false

  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(args) do
    receiver = Keyword.get(args, :receiver)

    children =
      if receiver do
        [receiver]
      else
        raise "a receiver module is required for accepting webmentions"
      end

    children =
      children ++
        [
          Libmention.Incoming.WorkerSupervisor.child_spec(args)
        ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
