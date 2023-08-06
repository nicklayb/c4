defmodule C4.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, name: C4.Game.Server.registry_name(), keys: :unique},
      {DynamicSupervisor, name: C4.Game.GamesSupervisor, strategy: :one_for_one},
      {Phoenix.PubSub, name: C4.PubSub.server_name()},
      {C4Tcp.Supervisor, name: C4.TcpServer}
    ]

    opts = [strategy: :one_for_one, name: C4.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
