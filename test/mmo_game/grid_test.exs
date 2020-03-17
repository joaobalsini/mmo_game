defmodule MmoGame.GridTest do
  use ExUnit.Case

  alias MmoGame.Grid

  describe "new/1" do
    test "Builds a proper grid when receives no walls" do
      assert {:ok, %Grid{rows: 10, columns: 10, walls: %{}}} =
               Grid.new(%{rows: 10, columns: 10, walls: []})
    end

    test "Doesn't build a grid if receives invalid parameters" do
      assert {:error, :invalid_grid_parameters} = Grid.new(%{rows: -1, columns: 0, walls: []})

      assert {:error, :invalid_grid_parameters} = Grid.new(%{rows: "a", columns: 1, walls: []})

      assert {:error, :invalid_grid_parameters} = Grid.new(%{rows: 10, columns: 10, walls: 1})
    end

    test "Builds a proper grid when receives proper walls" do
      rows = 10
      columns = 10
      walls = [{0, 0}, {0, 1}]

      assert {:ok,
              %Grid{rows: rows, columns: columns, walls: %{{0, 0} => true, {0, 1} => true}} = grid} =
               Grid.new(%{
                 rows: rows,
                 columns: columns,
                 walls: walls
               })
    end

    test "Doesn't build a grid if one of the walls are out of grid" do
      rows = 10
      columns = 10
      walls = [{0, 0}, {0, 10}]

      assert {:error, :invalid_wall_coordinate} =
               Grid.new(%{rows: rows, columns: columns, walls: walls})

      walls = [{10, 0}]

      assert {:error, :invalid_wall_coordinate} =
               Grid.new(%{rows: rows, columns: columns, walls: walls})
    end

    test "Doesn't build a grid if one of the walls dimensions are negative" do
      rows = 10
      columns = 10
      walls = [{-1, 0}]

      assert {:error, :invalid_wall_coordinate} =
               Grid.new(%{rows: rows, columns: columns, walls: walls})

      walls = [{0, -1}]

      assert {:error, :invalid_wall_coordinate} =
               Grid.new(%{rows: rows, columns: columns, walls: walls})
    end
  end

  describe "wall?/2" do
    setup do
      walls = [{0, 0}, {0, 9}, {9, 0}]

      {:ok, grid} =
        Grid.new(%{
          rows: 10,
          columns: 10,
          walls: walls
        })

      {:ok, %{grid: grid, walls: walls}}
    end

    test "Returns true for all the coordinates we have walls and false for other __VALID__ coordinates",
         %{grid: grid, walls: walls} do
      rows = grid.rows
      columns = grid.columns

      Enum.each(0..(rows - 1), fn row ->
        Enum.each(0..(columns - 1), fn column ->
          case {row, column} in walls do
            true ->
              assert Grid.wall?(grid, {row, column}) == {:ok, true}

            false ->
              assert Grid.wall?(grid, {row, column}) == {:ok, false}
          end
        end)
      end)
    end

    test "Returns error if coordinate is invalid or out of the grid", %{grid: grid} do
      assert Grid.wall?(grid, {0, 10}) == {:error, :invalid_coordinate}
      assert Grid.wall?(grid, {10, 0}) == {:error, :invalid_coordinate}
      assert Grid.wall?(grid, {-1, 0}) == {:error, :invalid_coordinate}
      assert Grid.wall?(grid, {0, -1}) == {:error, :invalid_coordinate}
      assert Grid.wall?(grid, {"a", 0}) == {:error, :invalid_coordinate}
    end
  end
end
