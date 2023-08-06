defmodule C4.Board do
  defstruct [:grid, :line_length]

  alias C4.Board
  alias C4.Board.LineFinder
  alias C4.Grid
  alias C4.PlayerSet

  @type player_cell :: PlayerSet.color()
  @type cell :: :empty | player_cell()
  @type t :: %Board{grid: Grid.t(cell()), line_length: non_neg_integer()}

  @width 7
  @height 6
  @default :empty
  @default_line_length 4

  @empty_grid Grid.new(@width, @height, @default)

  def new do
    %Board{grid: @empty_grid, line_length: @default_line_length}
  end

  @spec drop(t(), non_neg_integer(), player_cell()) ::
          {:ok, t()} | {:error, :column_full | :out_of_bounds}
  def drop(%Board{grid: %Grid{width: width}} = board, column_index, value)
      when column_index < width and column_index >= 0 do
    case first_empty_row(board, column_index) do
      -1 ->
        {:error, :column_full}

      row_index ->
        {:ok, map_grid(board, &Grid.put(&1, {row_index, column_index}, value))}
    end
  end

  def drop(%Board{}, _column_index, _value), do: {:error, :out_of_bounds}

  @type line_coordinates :: {
          Grid.cooridnate(),
          Grid.coordinate(),
          Grid.coordinate(),
          Grid.coordinate()
        }

  @type check_winner_result :: {:winner, player_cell(), line_coordinates()} | :tie | :incomplete
  @spec check_winner(t()) :: check_winner_result()
  def check_winner(%Board{} = board) do
    case LineFinder.find_lines(board) do
      [] ->
        if full?(board), do: :tie, else: :incomplete

      [{color, _} | _] = lines ->
        {:winner, color, Enum.map(lines, &elem(&1, 1))}
    end
  end

  defp full?(%Board{grid: grid}) do
    not Grid.any?(grid, &(Grid.get(grid, &1) == @default))
  end

  defp first_empty_row(%Board{grid: grid}, column_index) do
    Grid.reduce_while(grid, -1, fn
      {row_index, ^column_index} = coordinate, acc ->
        if Grid.get(grid, coordinate) != @default do
          {:halt, acc}
        else
          {:cont, row_index}
        end

      _coordinate, acc ->
        {:cont, acc}
    end)
  end

  defp map_grid(%Board{grid: grid} = board, function) do
    %Board{board | grid: function.(grid)}
  end

  @spec to_string(t()) :: String.t()
  def to_string(%Board{grid: grid}) do
    list = Grid.to_list(grid)

    Enum.map_join(list, "\n", fn row ->
      Enum.map_join(row, "", fn
        :empty -> " "
        :red -> "R"
        :blue -> "B"
      end)
    end)
  end
end
