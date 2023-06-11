defmodule Libmention.OutgoingSupervisor do
  @moduledoc false

  use DynamicSupervisor 

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    dbg init_arg
    # as part of starting the WebMentionSupervisor, we also
    # start the task of sending web mentions for all articles
    # already written via Tasks
    # send_web_mentions()
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
