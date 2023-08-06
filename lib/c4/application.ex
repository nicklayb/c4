defmodule C4.Application do
  use Application

  @tcp_server_name C4.TcpServer
  @impl true
  def start(_type, _args) do
    children = [
      {Registry, name: C4.Game.Server.registry_name(), keys: :unique},
      {DynamicSupervisor, name: C4.Game.GamesSupervisor, strategy: :one_for_one},
      {Phoenix.PubSub, name: C4.PubSub.server_name()},
      {C4Tcp.Supervisor, name: @tcp_server_name, port: tcp_server_port()}
    ]

    opts = [strategy: :one_for_one, name: C4.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp tcp_server_port do
    :c4
    |> Application.fetch_env!(@tcp_server_name)
    |> Keyword.fetch!(:port)
  end
end
