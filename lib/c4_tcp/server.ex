defmodule C4Tcp.Server do
  use GenServer

  alias C4Tcp.Supervisor, as: C4TcpSupervisor
  require Logger

  def start_link(args) do
    root_name = Keyword.fetch!(args, :root_name)
    port = Keyword.fetch!(args, :port)

    GenServer.start_link(__MODULE__, [root_name: root_name, port: port],
      name: C4TcpSupervisor.name(root_name, :server)
    )
  end

  def init(args) do
    state = new_state(args)
    port = option(state, :port)

    with {:ok, socket} <- :gen_tcp.listen(port, [:list, {:active, true}]) do
      log_info("Listening on #{port} -> #{inspect(socket)}")

      send(self(), :accept)

      {:ok, put_socket(state, socket)}
    end
  end

  @identifier_length 10
  def handle_info(:accept, state) do
    log_info("Accepting client")
    listen_socket = option(state, :socket)
    root_name = option(state, :root_name)
    id = C4.Generator.random_id(@identifier_length)

    with {:ok, client_socket} <- :gen_tcp.accept(listen_socket),
         {:ok, pid} <-
           C4TcpSupervisor.accept_client(root_name, client_socket, id) do
      :gen_tcp.controlling_process(client_socket, pid)
    else
      error ->
        log_error("Error: #{inspect(error)}")
    end

    send(self(), :accept)
    {:noreply, state}
  end

  def handle_info(message, state) do
    log_warn("Unhandled #{message}")
    {:noreply, state}
  end

  defp option(state, key, default \\ nil), do: Map.get(state, key, default)

  @valid_args ~w(port root_name)a
  defp new_state(args) do
    args
    |> Keyword.take(@valid_args)
    |> Enum.into(%{})
    |> Map.put(:socket, nil)
  end

  defp put_socket(state, socket), do: Map.put(state, :socket, socket)

  defp log_info(message), do: Logger.info("[#{inspect(__MODULE__)}] #{message}")
  defp log_warn(message), do: Logger.warn("[#{inspect(__MODULE__)}] #{message}")
  defp log_error(message), do: Logger.error("[#{inspect(__MODULE__)}] #{message}")
end
