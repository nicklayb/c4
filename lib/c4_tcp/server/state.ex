defmodule C4Tcp.Server.State do
  defstruct [:root_name, :listen_socket, :port]

  alias C4Tcp.Server.State
  alias C4Tcp.Supervisor, as: C4TcpSupervisor

  @type t :: %State{
          root_name: atom(),
          listen_socket: port() | nil,
          port: non_neg_integer()
        }
  @type argument :: {:socket, port()} | {:port, non_neg_integer()}

  @spec new([argument()]) :: t()
  def new(args) do
    %State{
      root_name: Keyword.fetch!(args, :root_name),
      port: Keyword.fetch!(args, :port)
    }
  end

  defp put_listen_socket(%State{} = state, listen_socket) do
    %State{state | listen_socket: listen_socket}
  end

  @spec listen(t()) :: {:ok, t()} | {:error, atom()}
  def listen(%State{port: port} = state) do
    with {:ok, socket} <- :gen_tcp.listen(port, [:list, {:active, true}]) do
      {:ok, put_listen_socket(state, socket)}
    end
  end

  @identifier_length 10
  def accept(%State{root_name: root_name, listen_socket: listen_socket}) do
    id = C4.Generator.random_id(@identifier_length)

    with {:ok, client_socket} <- :gen_tcp.accept(listen_socket),
         {:ok, pid} <-
           C4TcpSupervisor.accept_client(root_name, client_socket, id) do
      :gen_tcp.controlling_process(client_socket, pid)
      {:ok, pid}
    end
  end
end
