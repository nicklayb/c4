defmodule C4Tcp.Client do
  use GenServer, restart: :transient

  require Logger

  alias C4.Player
  alias C4.PlayerSet
  alias C4.Board
  alias C4.Game
  alias C4.Grid
  alias C4Tcp.Supervisor, as: C4TcpSupervisor

  def start_link(args) do
    root_name = Keyword.fetch!(args, :root_name)
    identifier = Keyword.fetch!(args, :identifier)
    socket = Keyword.fetch!(args, :socket)
    via_name = C4TcpSupervisor.via_name(root_name, identifier)

    GenServer.start_link(
      __MODULE__,
      [root_name: root_name, identifier: identifier, socket: socket],
      name: via_name
    )
  end

  def init(args) do
    state =
      args
      |> Enum.into(%{})
      |> Map.put(:current_game_id, nil)
      |> Map.put(:player, nil)
      |> Map.put(:player_color, nil)

    send(self(), :welcome)
    log_info(state, "Client started: #{inspect(Keyword.fetch!(args, :identifier))}")
    {:ok, state}
  end

  @welcome_message """

  # Welcome to C4!

  Pick a username to get started.
  """
  def handle_info(:welcome, state) do
    state = respond(state, @welcome_message)

    {:noreply, state}
  end

  def handle_info({:tcp, _socket, command}, state) do
    command
    |> to_string()
    |> String.trim()
    |> tap(fn
      "" ->
        :noop

      command ->
        log_info(state, "Handling: #{command}")
    end)
    |> handle_command(state)
  end

  def handle_info({:tcp_closed, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:joined, %Player{id: player_id}, game_id}, %{player: %{id: player_id}} = state) do
    state =
      state
      |> Map.put(:current_game_id, game_id)
      |> respond("You just joined game with code `#{game_id}`")

    C4.PubSub.subscribe({:game, game_id})

    {:noreply, state}
  end

  def handle_info({:countdown, counter}, state) do
    respond(state, "Starting... #{counter}", prompt: false)
    {:noreply, state}
  end

  def handle_info(
        {:started, %Game{players: player_set}},
        %{player: %Player{id: player_id} = player} = state
      ) do
    player_color = PlayerSet.player_color(player_set, player)
    state = Map.put(state, :player_color, player_color)
    respond(state, "Game has started")

    case PlayerSet.current_player(player_set) do
      %Player{id: ^player_id} ->
        respond(
          state,
          "It's your turn to play. Type `drop <index>` where index is the column you wanna drop"
        )

      _ ->
        respond(state, "It's your opponent's turn. Wait for him to play.")
    end

    {:noreply, state}
  end

  def handle_info(
        {:updated, %Game{board: board, players: player_set}},
        %{player: %Player{id: player_id}} = state
      ) do
    turn_text =
      case PlayerSet.current_player(player_set) do
        %Player{id: ^player_id} ->
          "Your turn."

        _ ->
          "Waiting for your opponent"
      end

    respond(state, board_to_string(board) <> "\n" <> turn_text)

    {:noreply, state}
  end

  def handle_info({:game_end, _, {:winner, %Player{name: name}, _}}, state) do
    state =
      state
      |> reset()
      |> respond("\n#{name} has won! Congratulation!\n")

    {:noreply, state}
  end

  def handle_info({:shutdown, _}, state) do
    state =
      state
      |> reset()
      |> respond("Game is shutting down due to inactivity")

    {:noreply, state}
  end

  def handle_info(message, state) do
    log_info(state, "Got message: #{inspect(message)}")
    {:noreply, state}
  end

  def terminate(_, state) do
    log_info(state, "Shutting down")
    :ok
  end

  @player_id_length 10
  @maximum_username_length 20
  @username_regex ~r/^[\w\d]+$/
  defp handle_command(username, %{player: nil} = state) do
    username = String.trim(username)

    cond do
      String.length(username) > @maximum_username_length ->
        respond(state, "That's a little long, pick a username with less than 20 characters")
        {:noreply, state}

      username == "" ->
        respond(state, "Invalid name enter at least one character")
        {:noreply, state}

      not Regex.match?(@username_regex, username) ->
        respond(
          state,
          "Username contains invalid characters, only alphanumerical characters are accepted, try again"
        )

        {:noreply, state}

      true ->
        player_id = C4.Generator.random_id(@player_id_length)
        player = Player.new(player_id, username)

        state =
          state
          |> Map.put(:player, player)
          |> respond("""
          Welcome, #{username}!

          Type `help` to get started.
          """)

        C4.PubSub.subscribe({:player, player_id})
        {:noreply, state}
    end
  end

  defp handle_command("new", %{player: player, current_game_id: nil} = state) do
    game_id = C4.Generator.random_id(:uppernumeric, 5)
    {:ok, _pid} = C4.Game.Server.start_link(game_id: game_id)

    C4.Game.Server.join(game_id, player)

    {:noreply, state}
  end

  defp handle_command("join " <> game_id, %{player: player, current_game_id: nil} = state) do
    C4.Game.Server.join(game_id, player)

    {:noreply, state}
  end

  defp handle_command(
         "drop " <> index,
         %{player: %Player{id: player_id}, current_game_id: game_id} = state
       )
       when is_binary(game_id) do
    with {int, _} <- Integer.parse(index) do
      C4.Game.Server.drop(game_id, player_id, int - 1)
    end

    {:noreply, state}
  end

  defp handle_command(
         "print",
         %{player: %Player{id: player_id}, current_game_id: current_game_id} = state
       )
       when is_binary(current_game_id) do
    board = C4.Game.Server.board(current_game_id, player_id)
    respond(state, board_to_string(board))
    {:noreply, state}
  end

  @help """
  Use one of the following command

  - `new`\t\tto start new game
  - `join <game>` to join an existing game
  - `quit`\tquits C4
  """
  defp handle_command("help", %{current_game_id: nil} = state) do
    respond(state, @help)
    {:noreply, state}
  end

  @help """
  Use one of the following command

  - `drop <col>`\t to drop a piece in the given column
  - `print`\t prints the board
  - `who`\t\t shows who's turn it is
  - `quit`\t quits C4
  """
  defp handle_command("help", state) do
    respond(state, @help)
    {:noreply, state}
  end

  defp handle_command("quit", %{socket: socket} = state) do
    :gen_tcp.shutdown(socket, :read_write)
    {:stop, :normal, state}
  end

  defp handle_command("", state) do
    prompt(state)
    {:noreply, state}
  end

  defp handle_command(_command, state) do
    respond(state, "No such command. Try `help` to know the available commands")
    {:noreply, state}
  end

  defp respond(%{socket: socket} = state, message, options \\ []) do
    message =
      if Keyword.get(options, :breakline, true) do
        message <> "\r\n"
      else
        message
      end

    with {:error, error} <- :gen_tcp.send(socket, message),
         do: log_error(state, "Error when sending: #{error}")

    if Keyword.get(options, :prompt, true), do: prompt(state), else: state
  end

  defp prompt(state) do
    username =
      case Map.get(state, :player) do
        %Player{name: name} -> name
        _ -> ""
      end

    username_and_game =
      case Map.get(state, :current_game_id) do
        nil -> username
        game_id -> "#{username}/#{game_id}"
      end

    color =
      case Map.get(state, :player_color) do
        nil ->
          ""

        color when is_atom(color) ->
          " " <> char(color)
      end

    respond(state, "#{username_and_game}#{color}> ", breakline: false, prompt: false)
  end

  defp log_info(state, message), do: Logger.info("[#{log_label(state)}] #{message}")
  defp log_error(state, message), do: Logger.error("[#{log_label(state)}] #{message}")
  defp log_label(%{identifier: identifier}), do: "#{inspect(__MODULE__)}/#{identifier}"

  def board_to_string(%Board{grid: grid}) do
    list = Grid.to_list(grid)

    indexes =
      list
      |> hd()
      |> Enum.reduce([], fn
        _, [] -> [1]
        _, [previous | _] = acc -> [previous + 1 | acc]
      end)
      |> Enum.reverse()
      |> Enum.map(&to_string/1)

    dash_line = Enum.map(0..(length(indexes) - 1), fn _ -> "-" end)

    (list ++ [dash_line, indexes])
    |> Enum.map_join("|\n|", fn row ->
      Enum.map_join(row, "|", fn
        :empty -> " "
        other -> char(other)
      end)
    end)
    |> then(&("\n\n|" <> &1 <> "|\n"))
  end

  defp reset(%{current_game_id: game_id} = state) do
    C4.PubSub.unsubscribe({:game, game_id})

    state
    |> Map.put(:player_color, nil)
    |> Map.put(:current_game_id, nil)
  end

  defp char(:red), do: "O"
  defp char(:blue), do: "X"
  defp char(char), do: char
end
