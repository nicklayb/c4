defmodule C4.BoardTest do
  use ExUnit.Case

  import C4.Support.Fixture

  alias C4.Board
  alias C4.Grid

  describe "new/0" do
    test "creates a new board" do
      assert %Board{
               grid: %Grid{
                 grid: %{
                   {0, 0} => :empty,
                   {0, 1} => :empty,
                   {0, 2} => :empty,
                   {0, 3} => :empty,
                   {0, 4} => :empty,
                   {0, 5} => :empty,
                   {0, 6} => :empty,
                   {1, 0} => :empty,
                   {1, 1} => :empty,
                   {1, 2} => :empty,
                   {1, 3} => :empty,
                   {1, 4} => :empty,
                   {1, 5} => :empty,
                   {1, 6} => :empty,
                   {2, 0} => :empty,
                   {2, 1} => :empty,
                   {2, 2} => :empty,
                   {2, 3} => :empty,
                   {2, 4} => :empty,
                   {2, 5} => :empty,
                   {2, 6} => :empty,
                   {3, 0} => :empty,
                   {3, 1} => :empty,
                   {3, 2} => :empty,
                   {3, 3} => :empty,
                   {3, 4} => :empty,
                   {3, 5} => :empty,
                   {3, 6} => :empty,
                   {4, 0} => :empty,
                   {4, 1} => :empty,
                   {4, 2} => :empty,
                   {4, 3} => :empty,
                   {4, 4} => :empty,
                   {4, 5} => :empty,
                   {4, 6} => :empty,
                   {5, 0} => :empty,
                   {5, 1} => :empty,
                   {5, 2} => :empty,
                   {5, 3} => :empty,
                   {5, 4} => :empty,
                   {5, 5} => :empty,
                   {5, 6} => :empty
                 },
                 width: 7,
                 height: 6
               }
             } = Board.new()
    end
  end

  describe "drop/3" do
    test "drops into an empty column" do
      board = Board.new()

      assert {:ok, red_dropped} = Board.drop(board, 4, :red)
      assert %Board{grid: %Grid{grid: %{{5, 4} => :red, {4, 4} => :empty}}} = red_dropped
      assert {:ok, blue_dropped} = Board.drop(red_dropped, 4, :blue)
      assert %Board{grid: %Grid{grid: %{{5, 4} => :red, {4, 4} => :blue}}} = blue_dropped
    end

    test "errors if column is full" do
      board = Board.new()
      assert {:ok, board} = Board.drop(board, 4, :red)
      assert {:ok, board} = Board.drop(board, 4, :blue)
      assert {:ok, board} = Board.drop(board, 4, :red)
      assert {:ok, board} = Board.drop(board, 4, :blue)
      assert {:ok, board} = Board.drop(board, 4, :red)
      assert {:ok, board} = Board.drop(board, 4, :blue)
      assert {:error, :column_full} = Board.drop(board, 4, :red)
    end
  end

  describe "check_winner/1" do
    setup [:create_board]

    @tag board: [
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :r, :_, :b, :_, :_, :_],
           [:_, :r, :r, :b, :_, :_, :_],
           [:_, :r, :b, :b, :_, :_, :_],
           [:r, :r, :b, :r, :r, :_, :_]
         ]
    test "has a winner", %{board: board} do
      assert {:winner, :red, [{{5, 1}, {4, 1}, {3, 1}, {2, 1}}]} == Board.check_winner(board)
    end

    @tag board: [
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :r, :_, :b, :_, :_, :_],
           [:_, :r, :r, :b, :_, :_, :_],
           [:_, :r, :b, :r, :_, :_, :_],
           [:r, :r, :b, :r, :r, :_, :_]
         ]
    test "has a winner with two lines", %{board: board} do
      assert {:winner, :red,
              [
                {{5, 4}, {4, 3}, {3, 2}, {2, 1}},
                {{5, 1}, {4, 1}, {3, 1}, {2, 1}}
              ]} == Board.check_winner(board)
    end

    @tag board: [
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :r, :_, :b, :_, :_, :_],
           [:_, :r, :r, :b, :_, :_, :_],
           [:_, :b, :b, :b, :_, :_, :_],
           [:r, :r, :b, :r, :r, :_, :_]
         ]
    test "has no winner yet", %{board: board} do
      assert :incomplete == Board.check_winner(board)
    end

    @tag board: [
           [:b, :r, :r, :b, :r, :r, :b],
           [:r, :b, :r, :b, :r, :r, :b],
           [:b, :b, :r, :b, :b, :b, :r],
           [:b, :b, :b, :r, :r, :b, :r],
           [:r, :r, :b, :b, :r, :r, :r],
           [:r, :r, :b, :r, :r, :b, :b]
         ]
    test "has a tie", %{board: board} do
      assert :tie == Board.check_winner(board)
    end
  end
end
