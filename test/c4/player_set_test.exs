defmodule C4.PlayerSetTest do
  use ExUnit.Case
  import C4.Support.Fixture

  alias C4.Player
  alias C4.PlayerSet

  describe "new/2" do
    test "creates a player set" do
      red_player = Player.new("red", "Red")
      blue_player = Player.new("blue", "Blue")

      assert %PlayerSet{red: ^red_player, blue: ^blue_player, current_player: :red} =
               PlayerSet.new(red_player, blue_player)
    end
  end

  describe "cycle_players/1" do
    setup [:create_player_set]

    test "cycles players", %{player_set: player_set} do
      assert %PlayerSet{current_player: :red} = player_set
      updated_player_set = PlayerSet.cycle_players(player_set)
      assert %PlayerSet{current_player: :blue} = updated_player_set
      updated_player_set = PlayerSet.cycle_players(updated_player_set)
      assert %PlayerSet{current_player: :red} = updated_player_set
    end
  end

  describe "current_player_color/1" do
    setup [:create_player_set]

    test "gets current player", %{player_set: player_set} do
      assert :red == PlayerSet.current_player_color(player_set)

      assert :blue ==
               player_set
               |> PlayerSet.cycle_players()
               |> PlayerSet.current_player_color()
    end
  end

  describe "current_player/1" do
    setup [:create_player_set]

    test "gets current player", %{player_set: player_set} do
      assert %Player{id: "RED"} = PlayerSet.current_player(player_set)

      assert %Player{id: "BLUE"} =
               player_set
               |> PlayerSet.cycle_players()
               |> PlayerSet.current_player()
    end
  end
end
