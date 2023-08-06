defmodule C4.GridTest do
  use ExUnit.Case

  alias C4.Grid

  describe "new/3" do
    test "creates a new grid with a default value" do
      width = 3
      height = 2

      assert %Grid{
               grid: %{
                 {0, 0} => :empty,
                 {0, 1} => :empty,
                 {0, 2} => :empty,
                 {1, 0} => :empty,
                 {1, 1} => :empty,
                 {1, 2} => :empty
               },
               width: ^width,
               height: ^height
             } = Grid.new(width, height, :empty)
    end
  end

  describe "get/2" do
    test "gets value in grid" do
      grid =
        3
        |> Grid.new(2)
        |> Grid.put({0, 2}, :ok)

      assert :ok = Grid.get(grid, {0, 2})
    end
  end

  describe "put/3" do
    test "puts value in grid" do
      grid = Grid.new(3, 2)

      assert %Grid{
               grid: %{
                 {0, 0} => nil,
                 {0, 1} => nil,
                 {0, 2} => :ok,
                 {1, 0} => nil,
                 {1, 1} => nil,
                 {1, 2} => nil
               }
             } = Grid.put(grid, {0, 2}, :ok)
    end
  end

  describe "map/2" do
    test "maps every grid cell" do
      grid = Grid.new(3, 2)

      assert %Grid{
               grid: %{
                 {0, 0} => "0;0",
                 {0, 1} => "0;1",
                 {0, 2} => "0;2",
                 {1, 0} => "1;0",
                 {1, 1} => "1;1",
                 {1, 2} => "1;2"
               }
             } =
               Grid.map(grid, fn {row_index, column_index}, _ ->
                 "#{row_index};#{column_index}"
               end)
    end
  end

  describe "any?/2" do
    test "checks for validity of a given function" do
      grid =
        3
        |> Grid.new(2)
        |> Grid.put({1, 2}, :ok)

      assert Grid.any?(grid, &(Grid.get(grid, &1) == :ok))
      refute Grid.any?(grid, &(Grid.get(grid, &1) == :nope))
    end
  end

  describe "reduce/3" do
    test "reduces the grid" do
      grid = Grid.new(3, 2)

      assert 6 == Grid.reduce(grid, 0, fn _, acc -> acc + 1 end)
    end
  end

  describe "reduce_while/3" do
    test "reduces until a condition is matched" do
      grid =
        3
        |> Grid.new(2)
        |> Grid.put({1, 2}, :ok)

      assert {{1, 2}, :ok} ==
               Grid.reduce_while(grid, nil, fn coordinate, _ ->
                 value = Grid.get(grid, coordinate)

                 if value != nil do
                   {:halt, {coordinate, value}}
                 else
                   {:cont, nil}
                 end
               end)
    end
  end

  describe "in_grid?/2" do
    test "checks if a coordinate is in the grid" do
      grid = Grid.new(3, 2)
      assert Grid.in_grid?(grid, {1, 2})
      refute Grid.in_grid?(grid, {1, 3})
      refute Grid.in_grid?(grid, {2, 2})
    end
  end

  describe "sibling/3" do
    test "gets a right sibling if exists" do
      grid =
        3
        |> Grid.new(2)
        |> Grid.put({1, 0}, :yellow)
        |> Grid.put({1, 1}, :red)
        |> Grid.put({1, 2}, :blue)

      assert {:ok, {1, 1}, :red} = Grid.sibling(grid, {0, 0}, :right_diagonal)
      assert {:ok, {1, 0}, :yellow} = Grid.sibling(grid, {0, 1}, :left_diagonal)
      assert {:ok, {1, 2}, :blue} = Grid.sibling(grid, {1, 1}, :right)
      assert {:ok, {1, 2}, :blue} = Grid.sibling(grid, {0, 2}, :down)
      assert {:error, :out_of_bounds} = Grid.sibling(grid, {2, 0}, :down)
    end
  end
end
