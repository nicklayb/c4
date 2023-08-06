defmodule C4.Grid do
  defstruct [:grid, :width, :height]
  alias C4.Grid

  @type coordinate :: {non_neg_integer(), non_neg_integer()}
  @type direction :: :right | :down | :right_diagonal | :left_diagonal
  @type grid(item) :: %{coordinate() => item}
  @type t(item) :: %Grid{grid: grid(item), width: non_neg_integer(), height: non_neg_integer()}

  def new(width, height, default \\ nil) do
    initialize_grid(%Grid{grid: %{}, width: width, height: height}, default)
  end

  @spec sibling(t(any()), coordinate(), direction()) ::
          {:ok, coordinate(), any()} | {:error, :out_of_bounds}
  def sibling(grid, coordinate, direction) do
    sibling_coordinate = sibling_coordinate(coordinate, direction)

    if in_grid?(grid, sibling_coordinate) do
      {:ok, sibling_coordinate, get(grid, sibling_coordinate)}
    else
      {:error, :out_of_bounds}
    end
  end

  defp sibling_coordinate({row_index, column_index}, :right), do: {row_index, column_index + 1}
  defp sibling_coordinate({row_index, column_index}, :down), do: {row_index + 1, column_index}

  defp sibling_coordinate({row_index, column_index}, :right_diagonal),
    do: {row_index + 1, column_index + 1}

  defp sibling_coordinate({row_index, column_index}, :left_diagonal),
    do: {row_index + 1, column_index - 1}

  @spec in_grid?(t(any()), coordinate()) :: boolean()
  def in_grid?(%Grid{width: width, height: height}, {row_index, column_index})
      when row_index >= 0 and column_index >= 0 do
    row_index < height and column_index < width
  end

  def in_grid?(_, _), do: false

  defp initialize_grid(%Grid{} = grid, value) do
    map(grid, fn _coordinate, _value -> value end)
  end

  def get(%Grid{grid: inner_grid}, coordinate), do: Map.get(inner_grid, coordinate)

  def put(%Grid{} = grid, coordinate, value) do
    map_grid(grid, &Map.put(&1, coordinate, value))
  end

  @type check() :: (coordinate() -> boolean())

  @spec any?(t(any()), check()) :: boolean()
  def any?(%Grid{} = grid, function) do
    reduce_while(grid, false, fn coordinate, _acc ->
      if function.(coordinate) do
        {:halt, true}
      else
        {:cont, false}
      end
    end)
  end

  @type mapper() :: (coordinate(), any() -> any())

  @spec map(t(any()), mapper()) :: any()
  def map(%Grid{} = grid, function) do
    inner_grid =
      reduce(grid, %{}, fn coordinate, acc ->
        current_value = get(grid, coordinate)
        Map.put(acc, coordinate, function.(coordinate, current_value))
      end)

    put_grid(grid, inner_grid)
  end

  @type reducer(output) :: (coordinate(), any() -> output)

  @spec reduce(t(any()), any(), reducer(any())) :: any()
  def reduce(%Grid{} = grid, initial, function) do
    reduce_while(grid, initial, fn coordinate, acc ->
      {:cont, function.(coordinate, acc)}
    end)
  end

  @type reducer_while() :: reducer({:halt, any()} | {:cont, any()})

  @spec reduce_while(t(any()), any(), reducer_while()) :: any()
  def reduce_while(%Grid{width: width, height: height}, initial, function) do
    Enum.reduce_while(0..(height - 1), initial, fn row_index, acc ->
      result =
        Enum.reduce_while(0..(width - 1), acc, fn column_index, acc ->
          coordinate = {row_index, column_index}

          case function.(coordinate, acc) do
            {:halt, result} -> {:halt, {:halt, result}}
            {:cont, result} -> {:cont, result}
          end
        end)

      case result do
        {:halt, acc} -> {:halt, acc}
        _ -> {:cont, result}
      end
    end)
  end

  defp map_grid(%Grid{grid: inner_grid} = grid, mapper) do
    %Grid{grid | grid: mapper.(inner_grid)}
  end

  defp put_grid(%Grid{} = grid, new_inner_grid) do
    %Grid{grid | grid: new_inner_grid}
  end

  @spec to_list(t(any())) :: [[any()]]
  def to_list(%Grid{width: width} = grid) do
    {_, total} =
      reduce(grid, {[], []}, fn {_, column_index} = coordinate, {current_line, acc} ->
        value = get(grid, coordinate)
        current_line = [value | current_line]

        if column_index + 1 == width do
          {[], [Enum.reverse(current_line) | acc]}
        else
          {current_line, acc}
        end
      end)

    Enum.reverse(total)
  end
end
