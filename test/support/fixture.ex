defmodule C4.Support.Fixture do
  alias C4.Board
  alias C4.Game
  alias C4.Grid
  alias C4.Player
  alias C4.PlayerSet

  def create_board(%{board: board}) do
    board = board(board)

    [board: board]
  end

  def create_player_set(context) do
    red_name = Map.get(context, :red, "Red")
    blue_name = Map.get(context, :blue, "Blue")
    player_set = player_set(red_name, blue_name)

    [player_set: player_set]
  end

  def create_game(context) do
    %PlayerSet{red: red, blue: blue} =
      Map.get_lazy(context, :player_set, fn ->
        context
        |> create_player_set()
        |> Keyword.get(:player_set)
      end)

    game = Game.new(red, blue)

    game =
      case Map.get(context, :template) do
        nil ->
          game

        template ->
          board = board(template)
          %Game{game | board: board}
      end

    [game: game]
  end

  def game(red_player, blue_player, board) do
    game = game(red_player, blue_player)

    %Game{game | board: board}
  end

  def game(red_player, blue_player) do
    Game.new(red_player, blue_player)
  end

  def board(template) when is_list(template) do
    board = Board.new()

    grid =
      Grid.map(board.grid, fn {row_index, column_index}, _ ->
        row = Enum.at(template, row_index)

        case Enum.at(row, column_index) do
          :r -> :red
          :b -> :blue
          :_ -> :empty
          other -> other
        end
      end)

    %Board{board | grid: grid}
  end

  def player(name) do
    Player.new(String.upcase(name), name)
  end

  def player_set(%Player{} = red, %Player{} = blue) do
    PlayerSet.new(red, blue)
  end

  def player_set(red, blue) do
    red
    |> player()
    |> player_set(player(blue))
  end
end
