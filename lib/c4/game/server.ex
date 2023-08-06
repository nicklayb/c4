defmodule C4.Game.Server do
  defstruct [:game, :game_id, :lobby, :status, :shutdown_timer]
  use GenServer, restart: :transient

  require Logger

  alias C4.Game
  alias C4.Game.Server
  alias C4.Player
  alias C4.PlayerSet

  @registry C4.Game.Registry
  @shutdown_timer :timer.minutes(5)

  def name(game_id), do: {:via, Registry, {@registry, game_id}}

  def registry_name, do: @registry

  def start_link(args) do
    game_id = Keyword.fetch!(args, :game_id)
    GenServer.start_link(__MODULE__, args, name: name(game_id))
  end

  def init(args) do
    server =
      debounce_shutdown(%Server{
        game: nil,
        game_id: Keyword.fetch!(args, :game_id),
        lobby: [],
        status: :waiting
      })

    log_info(server, "Game started")
    {:ok, server}
  end

  def join(name_or_pid, %Player{id: id, name: name}), do: join(name_or_pid, id, name)

  def join(name_or_pid, player_id, player_name) do
    user_action(name_or_pid, player_id, {:join, player_name})
  end

  def drop(name_or_pid, player_id, column_index) do
    user_action(name_or_pid, player_id, {:drop, column_index})
  end

  def start(name_or_pid, player_id) do
    user_action(name_or_pid, player_id, :start)
  end

  def game(name_or_pid, player_id) do
    user_request(name_or_pid, player_id, :game)
  end

  def current_player(name_or_pid, player_id) do
    user_request(name_or_pid, player_id, :current_player)
  end

  def alive?(name_or_pid) do
    if is_pid(name_or_pid) do
      Process.alive?(name_or_pid)
    else
      length(Registry.lookup(@registry, name_or_pid)) > 0
    end
  end

  defp user_request(name_or_pid, player_id, request) do
    pid = name_or_pid(name_or_pid)

    GenServer.call(pid, {:user_request, player_id, request})
  end

  defp user_action(name_or_pid, player_id, action) do
    pid = name_or_pid(name_or_pid)

    GenServer.cast(pid, {:user_action, player_id, action})
  end

  defp name_or_pid(name_or_pid) do
    case name_or_pid do
      pid when is_pid(pid) ->
        pid

      string when is_binary(string) ->
        name(string)
    end
  end

  def handle_info({:countdown_start, 0}, state) do
    {:noreply, start_game(state)}
  end

  def handle_info({:countdown_start, counter}, state) do
    Process.send_after(self(), {:countdown_start, counter - 1}, :timer.seconds(1))
    broadcast(state, {:countdown, counter})
    {:noreply, state}
  end

  def handle_info(:shutdown, %Server{game_id: game_id} = server) do
    broadcast(server, {:shutdown, game_id})
    log_info(server, "Game shutdown")
    {:stop, :normal, server}
  end

  def handle_cast(
        {:user_action, player_id, {:join, _player_name}},
        %Server{lobby: [_, _]} = state
      ) do
    state
    |> broadcast(player_id, {:error, :game_full})
    |> noreply()
  end

  def handle_cast(
        {:user_action, player_id, {:join, player_name}},
        %Server{game_id: game_id} = state
      ) do
    player = Player.new(player_id, player_name)

    state
    |> broadcast(player_id, {:joined, player, game_id})
    |> broadcast({:joined, player, game_id})
    |> join_player(player)
    |> noreply()
  end

  def handle_cast(
        {:user_action, player_id, :start},
        %Server{lobby: [%Player{id: first_player_id}, %Player{id: second_player_id}]} = state
      ) do
    if player_id in [first_player_id, second_player_id] do
      state
      |> start_game()
      |> noreply()
    else
      state
      |> broadcast(player_id, {:error, :game_not_started})
      |> noreply()
    end
  end

  def handle_cast(
        {:user_action, player_id, _action},
        %Server{game: nil} = state
      ) do
    state
    |> broadcast(player_id, {:error, :game_not_started})
    |> noreply()
  end

  def handle_cast(
        {:user_action, player_id, {:drop, column_index}},
        %Server{game: %Game{} = game} = state
      ) do
    if Game.current_player?(game, player_id) do
      case Game.drop(game, column_index) do
        {:ok, game} ->
          state
          |> put_game(Game.cycle_players(game))
          |> check_winner()
          |> noreply()

        {:error, error} ->
          state
          |> broadcast(player_id, {:error, error})
          |> noreply()
      end
    else
      state
      |> broadcast(player_id, {:error, :not_your_turn})
      |> noreply()
    end
  end

  def handle_call(
        {:user_request, _player_id, :game},
        _,
        %Server{game: %Game{} = game} = state
      ) do
    {:reply, game, state}
  end

  def handle_call({:user_request, _player_id, _}, _, %Server{} = state) do
    {:reply, nil, state}
  end

  def handle_call(
        {:user_request, _player_id, :current_player},
        _,
        %Server{game: %Game{players: player_set}} = server
      ) do
    current_player = PlayerSet.current_player(player_set)
    {:reply, current_player, server}
  end

  def handle_call(:current_player, server) do
    {:reply, nil, server}
  end

  defp broadcast(%Server{game_id: game_id} = state, message),
    do: tap(state, fn _ -> C4.PubSub.broadcast({:game, game_id}, message) end)

  defp broadcast(%Server{} = state, %Player{id: player_id}, message),
    do: broadcast(state, player_id, message)

  defp broadcast(%Server{} = state, player_id, message),
    do: tap(state, fn _ -> C4.PubSub.broadcast({:player, player_id}, message) end)

  defp join_player(%Server{lobby: lobby} = state, %Player{} = player) do
    players = [player | lobby]
    server = %Server{state | lobby: players}

    if length(players) == 2 do
      send(self(), {:countdown_start, 5})
    end

    server
  end

  defp put_game(%Server{} = state, %Game{} = game) do
    broadcast(%Server{state | game: game}, {:updated, game})
  end

  defp put_status(%Server{} = state, status) do
    %Server{state | status: status}
  end

  defp check_winner(%Server{game: %Game{players: players} = game} = state) do
    case Game.check_winner(game) do
      :incomplete ->
        state

      :tie ->
        state
        |> put_status(:tie)
        |> broadcast(:game_end)

      {:winner, color, lines} ->
        state
        |> put_status({:winner, PlayerSet.get_player(players, color), lines})
        |> then(&broadcast(&1, {:game_end, &1.game, &1.status}))
    end
  end

  defp start_game(%Server{lobby: [_, _] = players} = state) do
    [red_player, blue_player] = Enum.shuffle(players)
    game = Game.new(red_player, blue_player)

    state
    |> put_game(game)
    |> put_status(:running)
    |> then(&broadcast(&1, {:started, &1.game}))
  end

  defp debounce_shutdown(%{shutdown_timer: shutdown_timer} = server) do
    if is_reference(shutdown_timer), do: Process.cancel_timer(shutdown_timer)
    timer = Process.send_after(self(), :shutdown, @shutdown_timer)
    %Server{server | shutdown_timer: timer}
  end

  defp noreply(%Server{} = server) do
    server = debounce_shutdown(server)
    {:noreply, server}
  end

  defp log_info(state, message), do: Logger.info("[#{log_label(state)}] #{message}")
  defp log_error(state, message), do: Logger.error("[#{log_label(state)}] #{message}")
  defp log_label(%Server{game_id: game_id}), do: "#{inspect(__MODULE__)}/#{game_id}"
end
