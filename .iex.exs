alias Libmention.Supervisor
alias Libmention.Outgoing

opts = [
  outgoing: [
    user_agent: "",
    storage: Libmention.EtsStorage,
    proxy: [port: 8082]
  ]
]

start_supervisor = fn -> 
  Libmention.Supervisor.start_link(opts)
end
