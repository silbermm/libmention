defmodule Libmention.OutgoingSupervisor do
  @moduledoc false

  use DynamicSupervisor

  def start_link(opts), do: DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)
end
