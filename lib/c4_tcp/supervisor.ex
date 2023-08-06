defmodule C4Tcp.Supervisor do
  use Supervisor

  alias C4Tcp.Client

  def start_link(args) do
    args =
      args
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.put_new(:port, Enum.random(5000..6000))

    Supervisor.start_link(__MODULE__, args, name: Keyword.fetch!(args, :name))
  end

  def init(args) do
    name = Keyword.fetch!(args, :name)
    port = Keyword.fetch!(args, :port)

    children = [
      {DynamicSupervisor, name: name(name, :client_supervisor), strategy: :one_for_one},
      {Registry, name: name(name, :registry), keys: :unique},
      {C4Tcp.Server, root_name: name, port: port}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def accept_client(root_name, socket, identifier) do
    client_supervisor_name = name(root_name, :client_supervisor)

    DynamicSupervisor.start_child(
      client_supervisor_name,
      {Client, [root_name: root_name, socket: socket, identifier: identifier]}
    )
  end

  def name(root_name, :registry), do: Module.concat([root_name, Registry])
  def name(root_name, :client_supervisor), do: Module.concat([root_name, ClientSupervisor])
  def name(root_name, :server), do: Module.concat([root_name, Server])

  def via_name(root_name, identifier) do
    registry_name = name(root_name, :registry)
    {:via, Registry, {registry_name, identifier}}
  end
end
