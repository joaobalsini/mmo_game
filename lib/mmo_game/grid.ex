defmodule MmoGame.Grid do
  @moduledoc """
  Grid related functions.
  """

  @type t :: %__MODULE__{
          rows: pos_integer(),
          columns: pos_integer(),
          walls: %{optional(coordinate()) => boolean()}
        }

  @type row :: non_neg_integer()
  @type col :: non_neg_integer()
  @type coordinate :: {row, col}

  @enforce_keys [:rows, :columns, :walls]
  defstruct @enforce_keys

  alias MmoGame.Grid

  @spec new(%{
          rows: pos_integer(),
          columns: pos_integer(),
          walls: list(coordinate())
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
          wall_map_without_coordinates!(grid, {row, col})
        end)
      end)

    {:ok, grid}
  end

  def draw(_), do: {:error, :invalid_grid}

  defp wall_map_without_coordinates!(%Grid{} = grid, {row, col}) do
    case wall?(grid, {row, col}) do
      {:ok, true} -> %{wall: true}
      {:ok, false} -> %{wall: false}
    end
  end

  @spec default_grid :: {:ok, MmoGame.Grid.t()}
  def default_grid() do
    rows = 10
    colums = 10

    walls =
      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(colums - 1), fn column ->
          # returns something like
          # %{row: row, column: column, wall: true}
          default_wall_maps_case!(row, column)
        end)
      end)
      |> List.flatten()
      |> Enum.filter(& &1.wall)
      |> Enum.map(&{&1.row, &1.column})

    new(%{rows: rows, columns: colums, walls: walls})
  end

  defp default_wall_maps_case!(row, column) do
    case {row, column} do
      {row, _} when row in [0, 9] ->
        %{row: row, column: column, wall: true}

      {_, column} when column in [0, 9] ->
        %{row: row, column: column, wall: true}

      {4, column} when column in [1, 3, 4, 5, 6, 9] ->
        %{row: row, column: column, wall: true}

      {row, 4} when row in [4, 5, 6, 7, 9] ->
        %{row: row, column: column, wall: true}

      _ ->
        %{row: row, column: column, wall: false}
    end
  end

  @spec wall?(t(), coordinate()) :: {:error, :invalid_coordinate} | {:ok, boolean}
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
