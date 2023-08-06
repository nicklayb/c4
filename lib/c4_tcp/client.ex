defmodule C4Tcp.Client do
  use GenServer, restart: :transient

  require Logger

  alias C4.Player
  alias C4.PlayerSet
  alias C4.Game
  alias C4Tcp.Client.State
  alias C4Tcp.Supervisor, as: C4TcpSupervisor

  @spec start_link([State.argument()]) :: {:ok, pid()} | {:error, any()}
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

  @impl GenServer
  def init(args) do
    state = State.new(args)

    send(self(), :welcome)
    log_info(state, "Client started: #{state.identifier}")
    {:ok, state}
  end

  @welcome_message """

  # Welcome to C4!

  Pick a username to get started.
  """
  @impl GenServer
  def handle_info(:welcome, state) do
    state = respond(state, @welcome_message)

    {:noreply, state}
  end

  def handle_info({:tcp, _socket, command}, state) do
    command
    |> to_string()
    |> String.trim()
    |> tap(&if &1 != "", do: log_info(state, "Handling: #{&1}"))
    |> handle_command(state)
  end

  def handle_info({:tcp_closed, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info(
        {:joined, %Player{id: player_id}, game_id},
        %State{player: %Player{id: player_id}} = state
      ) do
    state =
      state
      |> State.put_game_id(game_id)
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
        %State{player: %Player{id: player_id} = player} = state
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
        {:updated, %Game{players: player_set} = game},
        %State{player: %Player{id: player_id}} = state
      ) do
    turn_text =
      case PlayerSet.current_player(player_set) do
        %Player{id: ^player_id} -> "Your turn."
        _ -> "Waiting for your opponent"
      end

    respond(state, Game.to_string(game, &State.char/1) <> "\n" <> turn_text)

    {:noreply, state}
  end

  def handle_info(
        {:game_end, _, {:winner, %Player{id: winner_player_id, name: name}, _}},
        %State{player: %Player{id: player_id}} = state
      ) do
    state = reset(state)

    message =
      if player_id == winner_player_id do
        "You won! Congratulation"
      else
        "Looks like #{name} has won, try again!"
      end

    respond(state, message)

    {:noreply, state}
  end

  def handle_info({:shutdown, _}, state) do
    state =
      state
      |> reset()
      |> respond("Game is shutting down due to inactivity")

    {:noreply, state}
  end

  def handle_info({:error, error}, state) do
    message =
      case error do
        :not_your_turn -> "This is not your turn, wait until your opponent has played"
        :column_full -> "This column is full, pick another one"
      end

    {:noreply, respond(state, message)}
  end

  def handle_info({:message, %Player{name: player_name}, message}, state) do
    respond(state, "\n[#{player_name}] #{message}")
    {:noreply, state}
  end

  def handle_info(message, state) do
    log_info(state, "Got message: #{inspect(message)}")
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_, state) do
    log_info(state, "Shutting down")
    :ok
  end

  @player_id_length 10
  @maximum_username_length 20
  @username_regex ~r/^[\w\d]+$/
  defp handle_command(username, %State{player: nil} = state) do
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
          |> State.put_player(player)
          |> respond("""
          Welcome, #{username}!

          Type `help` to get started.
          """)

        C4.PubSub.subscribe({:player, player_id})
        {:noreply, state}
    end
  end

  defp handle_command("new", %State{player: player, game_id: nil} = state) do
    game_id = C4.Generator.random_id(:uppernumeric, 5)
    {:ok, _pid} = C4.Game.Server.start_link(game_id: game_id)

    C4.Game.Server.join(game_id, player)

    {:noreply, state}
  end

  defp handle_command("join " <> game_id, %State{player: player, game_id: nil} = state) do
    C4.Game.Server.join(game_id, player)

    {:noreply, state}
  end

  defp handle_command(
         "drop " <> index,
         %State{player: %Player{id: player_id}, game_id: game_id} = state
       )
       when is_binary(game_id) do
    with {int, _} <- Integer.parse(index) do
      C4.Game.Server.drop(game_id, player_id, int - 1)
    end

    {:noreply, state}
  end

  defp handle_command(
         "print",
         %State{player: %Player{id: player_id}, game_id: game_id} = state
       )
       when is_binary(game_id) do
    with %Game{} = game <- C4.Game.Server.game(game_id, player_id) do
      respond(state, Game.to_string(game, &State.char/1))
    end

    {:noreply, state}
  end

  @help """
  Use one of the following command

  - `new`\t\tto start new game
  - `join <game>` to join an existing game
  - `quit`\tquits C4
  """
  defp handle_command("help", %State{game_id: nil} = state) do
    respond(state, @help)
    {:noreply, state}
  end

  @help """
  Use one of the following command

  - `drop <col>`\t to drop a piece in the given column
  - `print`\t prints the board
  - `who`\t\t shows who's turn it is
  - `msg <message>` sends message to the game
  - `quit`\t quits C4
  """
  defp handle_command("help", state) do
    respond(state, @help)
    {:noreply, state}
  end

  defp handle_command("quit", %State{socket: socket} = state) do
    :gen_tcp.shutdown(socket, :read_write)
    {:stop, :normal, state}
  end

  defp handle_command(
         "msg " <> text,
         %State{player: %Player{} = player, game_id: game_id} = state
       )
       when is_binary(game_id) and text != "" do
    C4.PubSub.broadcast({:game, game_id}, {:message, player, text})
    {:noreply, state}
  end

  defp handle_command("who", %State{game_id: game_id, player: %Player{id: player_id}} = state)
       when is_binary(game_id) do
    state =
      case C4.Game.Server.current_player(game_id, player_id) do
        %Player{id: ^player_id} ->
          respond(state, "It's your turn to play")

        %Player{name: player_name} ->
          respond(state, "It's #{player_name}'s turn")

        _ ->
          state
      end

    {:noreply, state}
  end

  defp handle_command("", state) do
    prompt(state)
    {:noreply, state}
  end

  defp handle_command(_command, state) do
    respond(state, "No such command. Try `help` to know the available commands")
    {:noreply, state}
  end

  defp respond(%State{socket: socket} = state, message, options \\ []) do
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

  defp prompt(%State{} = state) do
    prompt_text = State.prompt_text(state)

    respond(state, "#{prompt_text}> ", breakline: false, prompt: false)
  end

  defp log_info(state, message), do: Logger.info("[#{log_label(state)}] #{message}")
  defp log_error(state, message), do: Logger.error("[#{log_label(state)}] #{message}")
  defp log_label(%State{identifier: identifier}), do: "#{inspect(__MODULE__)}/#{identifier}"

  defp reset(%State{game_id: game_id} = state) do
    C4.PubSub.unsubscribe({:game, game_id})

    State.clear_game(state)
  end
end
