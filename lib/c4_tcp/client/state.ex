defmodule C4Tcp.Client.State do
  defstruct [:root_name, :identifier, :socket, :game_id, :player, :player_color, :state]

  alias C4.Player
  alias C4.PlayerSet
  alias C4Tcp.Client.State

  @type root_name :: atom()
  @type client_identifier :: String.t()
  @type socket :: port()

  @type t :: %State{
          root_name: root_name(),
          identifier: client_identifier(),
          socket: socket(),
          game_id: String.t() | nil,
          player: Player.t() | nil,
          player_color: PlayerSet.color() | nil
        }

  @type argument ::
          {:root_name, root_name()} | {:identifier, client_identifier()} | {:socket, socket()}

  @spec new([argument()]) :: t()
  def new(args) do
    root_name = Keyword.fetch!(args, :root_name)
    identifier = Keyword.fetch!(args, :identifier)
    socket = Keyword.fetch!(args, :socket)

    %State{
      root_name: root_name,
      identifier: identifier,
      socket: socket
    }
  end

  @spec clear_game(t()) :: t()
  def clear_game(%State{} = state) do
    %State{state | player_color: nil, game_id: nil}
  end

  @spec put_game_id(t(), String.t()) :: t()
  def put_game_id(%State{} = state, game_id), do: %State{state | game_id: game_id}

  @spec put_player_color(t(), PlayerSet.player_color()) :: t()
  def put_player_color(%State{} = state, player_color),
    do: %State{state | player_color: player_color}

  @spec put_player(t(), Player.t()) :: t()
  def put_player(%State{} = state, %Player{} = player), do: %State{state | player: player}

  @spec prompt_text(t()) :: String.t()
  def prompt_text(%State{player_color: player_color, player: player, game_id: game_id}) do
    username =
      case player do
        %Player{name: name} -> name
        _ -> ""
      end

    username_and_game =
      case game_id do
        nil -> username
        game_id -> "#{username}/#{game_id}"
      end

    color =
      case player_color do
        nil ->
          ""

        color when is_atom(color) ->
          " " <> char(color)
      end

    "#{username_and_game}#{color}"
  end

  def char(:red), do: "O"
  def char(:blue), do: "X"
  def char(char), do: char
end
