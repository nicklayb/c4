defmodule C4.Board.LineFinderTest do
  use ExUnit.Case

  import C4.Support.Fixture

  alias C4.Board
  alias C4.Board.LineFinder

  describe "find_lines/1" do
    setup [:create_board]

    @tag board: [
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :b, :_, :_, :_, :_, :_],
           [:_, :b, :b, :_, :_, :_, :_],
           [:_, :r, :b, :b, :_, :_, :_],
           [:r, :b, :r, :r, :b, :_, :_]
         ]

    test "find one line left diagonal", %{board: board} do
      assert [{:blue, {{5, 4}, {4, 3}, {3, 2}, {2, 1}}}] = LineFinder.find_lines(board)
    end

    @tag board: [
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :b, :_, :r, :_, :_, :_],
           [:_, :b, :r, :b, :_, :_, :_],
           [:_, :r, :b, :b, :_, :_, :_],
           [:r, :b, :r, :r, :b, :_, :_]
         ]

    test "find one line right diagonal", %{board: board} do
      assert [{:red, {{5, 0}, {4, 1}, {3, 2}, {2, 3}}}] = LineFinder.find_lines(board)
    end

    @tag board: [
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :r, :_, :r, :_, :_, :_],
           [:_, :b, :b, :b, :_, :_, :_],
           [:_, :r, :b, :b, :_, :_, :_],
           [:r, :r, :r, :r, :b, :_, :_]
         ]

    test "find one line horizontal", %{board: board} do
      assert [{:red, {{5, 3}, {5, 2}, {5, 1}, {5, 0}}}] = LineFinder.find_lines(board)
    end

    @tag board: [
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :r, :_, :r, :_, :_, :_],
           [:_, :r, :b, :b, :_, :_, :_],
           [:_, :r, :b, :b, :_, :_, :_],
           [:r, :r, :b, :r, :b, :_, :_]
         ]

    test "find one line vertical", %{board: board} do
      assert [{:red, {{5, 1}, {4, 1}, {3, 1}, {2, 1}}}] = LineFinder.find_lines(board)
    end

    @tag board: [
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :r, :_, :b, :_, :_, :_],
           [:_, :r, :r, :b, :_, :_, :_],
           [:_, :r, :b, :r, :_, :_, :_],
           [:r, :r, :b, :r, :r, :_, :_]
         ]

    test "find two line", %{board: board} do
      assert [
               {:red, {{5, 4}, {4, 3}, {3, 2}, {2, 1}}},
               {:red, {{5, 1}, {4, 1}, {3, 1}, {2, 1}}}
             ] = LineFinder.find_lines(board)
    end

    @tag board: [
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :_, :_, :_, :_, :_, :_],
           [:_, :r, :_, :b, :_, :_, :_],
           [:_, :r, :r, :b, :_, :_, :_],
           [:_, :b, :b, :b, :_, :_, :_],
           [:r, :r, :b, :r, :r, :_, :_]
         ]
    test "find no line", %{board: board} do
      assert [] == LineFinder.find_lines(board)
      assert [] == LineFinder.find_lines(Board.new())
    end
  end
end
