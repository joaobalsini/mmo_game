defmodule MmoGame.Grid do
  @moduledoc """
  Grid related functions.
  """

  @type t :: %__MODULE__{
          rows: integer(),
          columns: integer(),
          walls: map()
        }

  @enforce_keys [:rows, :columns, :walls]
  defstruct @enforce_keys

  alias MmoGame.Grid

  @spec new(%{
          rows: integer(),
          columns: integer(),
          walls: list({integer(), integer()})
        }) ::
          {:error, :invalid_grid_parameters | :invalid_wall_coordinate} | {:ok, t()}
  def new(%{rows: rows, columns: columns, walls: walls})
      when is_integer(rows) and is_integer(columns) and is_list(walls) and
             rows > 0 and columns > 0 do
    struct(Grid, %{rows: rows, columns: columns, walls: %{}})
    |> place_walls(walls)
  end

  def new(_), do: {:error, :invalid_grid_parameters}

  @spec draw(t()) :: {:ok, [[%{wall: boolean()}]]} | {:error, :invalid_grid}
  def draw(%Grid{rows: rows, columns: columns} = grid) do
    grid =
      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(columns - 1), fn col ->
          case wall?(grid, {row, col}) do
            {:ok, true} -> %{wall: true}
            {:ok, false} -> %{wall: false}
          end
        end)
      end)

    {:ok, grid}
  end

  def draw(_), do: {:error, :invalid_grid}

  @spec wall?(t(), {integer(), integer()}) :: {:error, :invalid_coordinate} | {:ok, boolean}
  def wall?(
        %Grid{rows: rows, columns: columns, walls: walls},
        {row, column}
      )
      when is_integer(row) and is_integer(column) and row < rows and column < columns and row >= 0 and
             column >= 0,
      do: {:ok, walls[{row, column}] == true}

  def wall?(
        _grid,
        _coordinate
      ),
      do: {:error, :invalid_coordinate}

  defp place_walls(%Grid{} = grid, []), do: {:ok, grid}

  defp place_walls(%Grid{} = grid, new_walls) do
    grid =
      Enum.reduce_while(new_walls, grid, fn wall, acc ->
        place_wall(acc, wall)
      end)

    case grid do
      %Grid{} = grid ->
        {:ok, grid}

      {:error, :invalid_wall_coordinate} ->
        {:error, :invalid_wall_coordinate}
    end
  end

  defp place_wall(%Grid{rows: rows, columns: columns, walls: walls} = grid, {row, column})
       when is_integer(row) and is_integer(column) and
              row < rows and column < columns and row >= 0 and
              column >= 0 do
    updated_walls = Map.put(walls, {row, column}, true)
    {:cont, Map.put(grid, :walls, updated_walls)}
  end

  defp place_wall(
         _grid,
         _coordinate
       ),
       do: {:halt, {:error, :invalid_wall_coordinate}}
end
