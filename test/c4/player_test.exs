defmodule C4.PlayerTest do
  use ExUnit.Case

  alias C4.Player

  describe "new/2" do
    test "creates a player" do
      assert %Player{id: "id", name: "name"} == Player.new("id", "name")
    end
  end
end
