defmodule C4.Board.LineFinder do
  alias C4.Board
  alias C4.Grid

  @directions ~w(horizontal vertical right_diagonal left_diagonal)a

  @spec find_lines(Board.t()) :: [{Board.color(), Board.line_coordinates()}]
  def find_lines(%Board{grid: grid, line_length: line_length}) do
    Grid.reduce(grid, [], fn coordinate, acc ->
      case Grid.get(grid, coordinate) do
        :empty ->
          acc

        color ->
          Enum.reduce(
            @directions,
            acc,
            &add_line(&2, color, get_line(&1, grid, coordinate, color, line_length))
          )
      end
    end)
  end

  defp get_line(direction, grid, coordinate, color, line_length) do
    direction = direction_sibling(direction)

    result =
      Enum.reduce_while(1..(line_length - 1), {coordinate, []}, fn _, {current_coordinate, acc} ->
        case Grid.sibling(grid, current_coordinate, direction) do
          {:ok, sibiling_coordinate, ^color} ->
            {:cont, {sibiling_coordinate, [current_coordinate | acc]}}

          _ ->
            {:halt, nil}
        end
      end)

    case result do
      {current_coordinate, [first, second, third]} -> {current_coordinate, first, second, third}
      _ -> nil
    end
  end

  defp direction_sibling(:horizontal), do: :right
  defp direction_sibling(:vertical), do: :down
  defp direction_sibling(:right_diagonal), do: :right_diagonal
  defp direction_sibling(:left_diagonal), do: :left_diagonal

  defp add_line(acc, _color, nil), do: acc

  defp add_line(acc, color, line) do
    if not line_present?(acc, line) do
      [{color, line} | acc]
    else
      acc
    end
  end

  defp line_present?(acc, line) do
    Enum.any?(acc, fn {_color, coordinates} -> same_line?(coordinates, line) end)
  end

  def same_line?({_, _, _, _} = current_line, {_, _, _, _} = checking_line) do
    current_line = Tuple.to_list(current_line)
    checking_line = Tuple.to_list(checking_line)

    current_line
    |> Enum.reduce([], fn coordinate, acc ->
      if coordinate in checking_line, do: [coordinate | acc], else: acc
    end)
    |> then(fn
      [] -> false
      [_] -> false
      _ -> true
    end)
  end

  def same_line?(_, _), do: false
end
