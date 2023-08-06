defmodule C4Tcp.Server do
  use GenServer

  alias C4Tcp.Server.State
  alias C4Tcp.Supervisor, as: C4TcpSupervisor
  require Logger

  def start_link(args) do
    root_name = Keyword.fetch!(args, :root_name)
    port = Keyword.fetch!(args, :port)

    GenServer.start_link(__MODULE__, [root_name: root_name, port: port],
      name: C4TcpSupervisor.name(root_name, :server)
    )
  end

  @impl GenServer
  def init(args) do
    state = State.new(args)

    with {:ok, %State{port: port, listen_socket: socket} = state} <- State.listen(state) do
      log_info("Listening on #{port} -> #{inspect(socket)}")

      send(self(), :accept)
      {:ok, state}
    end
  end

  @impl GenServer
  def handle_info(:accept, state) do
    log_info("Accepting client")

    with {:error, error} <- State.accept(state), do: log_error("Error: #{inspect(error)}")

    send(self(), :accept)
    {:noreply, state}
  end

  def handle_info(message, state) do
    log_warn("Unhandled #{message}")
    {:noreply, state}
  end

  defp log_info(message), do: Logger.info("[#{inspect(__MODULE__)}] #{message}")
  defp log_warn(message), do: Logger.warn("[#{inspect(__MODULE__)}] #{message}")
  defp log_error(message), do: Logger.error("[#{inspect(__MODULE__)}] #{message}")
end
