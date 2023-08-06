defmodule C4.PlayerSet do
  defstruct [:red, :blue, current_player: :red]

  alias C4.Player
  alias C4.PlayerSet

  @type color :: :red | :blue
  @type t :: %PlayerSet{red: Player.t(), blue: Player.t(), current_player: color()}

  @spec new(Player.t(), Player.t()) :: t()
  def new(%Player{} = red_player, %Player{} = blue_player) do
    %PlayerSet{red: red_player, blue: blue_player}
  end

  @spec cycle_players(t()) :: t()
  def cycle_players(%PlayerSet{current_player: :red} = player_set),
    do: %PlayerSet{player_set | current_player: :blue}

  def cycle_players(%PlayerSet{current_player: :blue} = player_set),
    do: %PlayerSet{player_set | current_player: :red}

  @spec current_player(t()) :: Player.t()
  def current_player(%PlayerSet{current_player: current_player} = player_set),
    do: get_player(player_set, current_player)

  def get_player(%PlayerSet{red: %Player{} = red_player}, :red), do: red_player
  def get_player(%PlayerSet{blue: %Player{} = blue_player}, :blue), do: blue_player

  @spec current_player_color(t()) :: color()
  def current_player_color(%PlayerSet{current_player: current_player}), do: current_player

  def player_color(%PlayerSet{red: %Player{id: player_id}}, %Player{id: player_id}), do: :red
  def player_color(%PlayerSet{blue: %Player{id: player_id}}, %Player{id: player_id}), do: :blue
end
