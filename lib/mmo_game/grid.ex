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
  @type move_direction :: :up | :down | :left | :right
  @move_directions [:up, :down, :left, :right]

  @enforce_keys [:rows, :columns, :walls]
  defstruct @enforce_keys

  @spec new(%{
          rows: pos_integer(),
          columns: pos_integer(),
          walls: list(coordinate())
        }) ::
          {:error, :invalid_grid_parameters | :invalid_wall_coordinate} | {:ok, t()}
  def new(%{rows: rows, columns: columns, walls: walls})
      when is_integer(rows) and is_integer(columns) and is_list(walls) and
             rows > 0 and columns > 0 do
    struct(__MODULE__, %{rows: rows, columns: columns, walls: %{}})
    |> place_walls(walls)
  end

  def new(_), do: {:error, :invalid_grid_parameters}

  defp place_walls(%__MODULE{} = grid, []), do: {:ok, grid}

  defp place_walls(%__MODULE{} = grid, new_walls) do
    grid =
      Enum.reduce_while(new_walls, grid, fn wall, acc ->
        place_wall(acc, wall)
      end)

    case grid do
      %__MODULE{} = grid ->
        {:ok, grid}

      {:error, :invalid_wall_coordinate} ->
        {:error, :invalid_wall_coordinate}
    end
  end

  defp place_wall(%__MODULE{rows: rows, columns: columns, walls: walls} = grid, {row, column})
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

  @spec draw(t(), %{optional(MmoGame.Grid.coordinate()) => [Hero.hero_name()]}) ::
          {:ok,
           [
             [
               %{
                 required(:wall) => boolean(),
                 optional(coordinate()) => [{MmoGame.Hero.hero_name(), :hero_dead | :hero_alive}]
               }
             ]
           ]}
          | {:error, :invalid_grid}
  def draw(%__MODULE{rows: rows, columns: columns} = grid, heroes_coordinates)
      when is_map(heroes_coordinates) do
    grid =
      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(columns - 1), fn col ->
          wall_map_without_coordinates!(grid, {row, col})
          |> Map.merge(map_of_heroes_in_coordinate({row, col}, heroes_coordinates))
        end)
      end)

    {:ok, grid}
  end

  def draw(_, _), do: {:error, :invalid_grid}

  defp map_of_heroes_in_coordinate(coordinate, heroes_coordinates) do
    case Map.get(heroes_coordinates, coordinate, nil) do
      nil -> %{}
      list -> %{heroes: list}
    end
  end

  # Used for random position on the board
  defp draw_with_coordinates!(%__MODULE{rows: rows, columns: columns} = grid) do
    Enum.map(0..(rows - 1), fn row ->
      Enum.map(0..(columns - 1), fn col ->
        wall_map_with_coordinates!(grid, {row, col})
      end)
    end)
  end

  defp wall_map_without_coordinates!(%__MODULE{} = grid, {row, col}) do
    case wall?(grid, {row, col}) do
      {:ok, true} -> %{wall: true}
      {:ok, false} -> %{wall: false}
    end
  end

  defp wall_map_with_coordinates!(%__MODULE{} = grid, {row, col}) do
    case wall?(grid, {row, col}) do
      {:ok, true} -> %{row: row, col: col, wall: true}
      {:ok, false} -> %{row: row, col: col, wall: false}
    end
  end

  @spec default_grid :: {:ok, t()}
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

  @spec random_non_wall_position(t()) ::
          {:ok, coordinate()} | {:error, :invalid_grid}
  def random_non_wall_position(%__MODULE{} = grid) do
    map_element =
      grid
      |> draw_with_coordinates!()
      |> List.flatten()
      |> Enum.filter(&(!&1.wall))
      |> Enum.random()

    {:ok, {map_element.row, map_element.col}}
  end

  def random_non_wall_position(_), do: {:error, :invalid_grid}

  defp wall?(
         %__MODULE{rows: rows, columns: columns, walls: walls},
         {row, column}
       )
       when is_integer(row) and is_integer(column) and row < rows and column < columns and
              row >= 0 and
              column >= 0,
       do: {:ok, walls[{row, column}] == true}

  @spec can_move?(t(), coordinate(), move_direction()) ::
          {:error, :invalid_move} | {:ok, coordinate()}
  # I'm considering a hero will never reach grid border (grid always have walls on its border)
  def can_move?(%__MODULE{} = grid, {_row, _column} = coordinate, direction)
      when direction in @move_directions do
    new_coordinate = adjacent_coordinate(coordinate, direction)
    check_move_and_return(grid, new_coordinate)
  end

  def can_move?(_, _, _), do: {:error, :invalid_move_parameters}

  defp check_move_and_return(%__MODULE{} = grid, {new_row, new_column}) do
    case wall?(grid, {new_row, new_column}) do
      {:ok, true} -> {:error, :invalid_move}
      {:ok, false} -> {:ok, {new_row, new_column}}
    end
  end

  defp adjacent_coordinate({row, column}, :up), do: {row - 1, column}
  defp adjacent_coordinate({row, column}, :right), do: {row, column + 1}
  defp adjacent_coordinate({row, column}, :down), do: {row + 1, column}
  defp adjacent_coordinate({row, column}, :left), do: {row, column - 1}

  defp adjacent_coordinate(coordinate, :up_right),
    do: adjacent_coordinate(coordinate, :up) |> adjacent_coordinate(:right)

  defp adjacent_coordinate(coordinate, :down_right),
    do: adjacent_coordinate(coordinate, :down) |> adjacent_coordinate(:right)

  defp adjacent_coordinate(coordinate, :down_left),
    do: adjacent_coordinate(coordinate, :down) |> adjacent_coordinate(:left)

  defp adjacent_coordinate(coordinate, :up_left),
    do: adjacent_coordinate(coordinate, :up) |> adjacent_coordinate(:left)

  @spec calculate_perimeter!(t(), coordinate()) :: [coordinate()] | no_return()
  def calculate_perimeter!(%__MODULE{} = grid, coordinate) do
    # run clockwise starting on top
    perimeter = [:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left]

    Enum.map(perimeter, fn direction ->
      coordinate = adjacent_coordinate(coordinate, direction)
      check_move_and_return(grid, coordinate) |> elem(1)
    end)
    |> Enum.filter(&(&1 != :invalid_move))
  end
end
