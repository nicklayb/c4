defmodule C4.GameTest do
  use ExUnit.Case
  import C4.Support.Fixture

  alias C4.Board
  alias C4.Game
  alias C4.PlayerSet

  describe "new/2" do
    setup [:create_player_set]

    test "creates a game", %{player_set: %{red: red_player, blue: blue_player}} do
      new_board = Board.new()

      assert %Game{
               players: %PlayerSet{red: ^red_player, blue: ^blue_player, current_player: :red},
               board: ^new_board
             } = Game.new(red_player, blue_player)
    end
  end

  describe "cycle_players/1" do
    setup [:create_game]

    test "cycles players", %{game: game} do
      assert %Game{players: %PlayerSet{current_player: :red}} = game
      assert %Game{players: %PlayerSet{current_player: :blue}} = Game.cycle_players(game)

      assert %Game{players: %PlayerSet{current_player: :red}} =
               game
               |> Game.cycle_players()
               |> Game.cycle_players()
    end
  end
end
