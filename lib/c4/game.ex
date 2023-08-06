defmodule C4.Game do
  defstruct [:board, :players]

  alias C4.Board
  alias C4.Game
  alias C4.Grid
  alias C4.Player
  alias C4.PlayerSet

  @type t :: %Game{players: PlayerSet.t(), board: Board.t()}

  @spec new(Player.t(), Player.t()) :: t()
  def new(%Player{} = red_player, %Player{} = blue_player) do
    %Game{players: PlayerSet.new(red_player, blue_player), board: Board.new()}
  end

  @spec cycle_players(t()) :: t()
  def cycle_players(%Game{players: %PlayerSet{} = player_set} = game),
    do: %Game{game | players: PlayerSet.cycle_players(player_set)}

  @spec drop(t(), non_neg_integer()) :: {:ok, t()} | {:error, :column_full | :out_of_bounds}
  def drop(
        %Game{players: %PlayerSet{} = players, board: %Board{} = board} = game,
        column_index
      ) do
    color = PlayerSet.current_player_color(players)

    with {:ok, updated_board} <- Board.drop(board, column_index, color) do
      {:ok, %Game{game | board: updated_board}}
    end
  end

  @spec check_winner(t()) :: Board.check_winner_result()
  def check_winner(%Game{board: %Board{} = board}), do: Board.check_winner(board)

  @spec current_player?(t(), Player.id()) :: boolean()
  def current_player?(%Game{players: %PlayerSet{} = players}, player_id) do
    %Player{id: current_player_id} = PlayerSet.current_player(players)
    current_player_id == player_id
  end

  @spec to_string(t(), function()) :: String.t()
  def to_string(%Game{board: %Board{grid: grid}}, char_mapper) do
    list = Grid.to_list(grid)

    indexes =
      list
      |> hd()
      |> Enum.reduce([], fn
        _, [] -> [1]
        _, [previous | _] = acc -> [previous + 1 | acc]
      end)
      |> Enum.reverse()
      |> Enum.map(&Kernel.to_string/1)

    dash_line = Enum.map(0..(length(indexes) - 1), fn _ -> "-" end)

    (list ++ [dash_line, indexes])
    |> Enum.map_join("|\n|", fn row ->
      Enum.map_join(row, "|", fn
        :empty -> " "
        other -> char_mapper.(other)
      end)
    end)
    |> then(&("\n\n|" <> &1 <> "|\n"))
  end
end
