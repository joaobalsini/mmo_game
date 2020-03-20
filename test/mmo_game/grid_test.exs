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

  describe("draw/1") do
    test "draws a valid grid properly" do
      walls = [{0, 0}, {0, 9}, {9, 0}]
      rows = 10
      columns = 10

      {:ok, grid} =
        Grid.new(%{
          rows: rows,
          columns: columns,
          walls: walls
        })

      assert {:ok, drawn_grid} = Grid.draw(grid)

      Enum.each(0..(rows - 1), fn row ->
        Enum.each(0..(columns - 1), fn column ->
          element =
            drawn_grid
            |> Enum.at(row)
            |> Enum.at(column)

          case Grid.wall?(grid, {row, column}) do
            {:ok, true} ->
              assert element == %{wall: true}

            {:ok, false} ->
              assert element == %{wall: false}
          end
        end)
      end)
    end

    test "returns {:error, :invalid_grid} if passed param is not a grid" do
      assert {:error, :invalid_grid} = Grid.draw(0)
      assert {:error, :invalid_grid} = Grid.draw("a")
      assert {:error, :invalid_grid} = Grid.draw(%{})
      assert {:error, :invalid_grid} = Grid.draw(nil)
    end
  end

  describe "random_non_wall_position/1" do
    test "returns a random position" do
      walls = [{0, 0}, {0, 9}, {9, 0}]
      rows = 10
      columns = 10

      {:ok, grid} =
        Grid.new(%{
          rows: rows,
          columns: columns,
          walls: walls
        })

      {:ok, first_guess} = Grid.random_non_wall_position(grid)
      {:ok, second_guess} = Grid.random_non_wall_position(grid)
      assert first_guess != second_guess
    end

    test "return {:error, :invalid_grid} if passed param is not a grid" do
      assert {:error, :invalid_grid} = Grid.random_non_wall_position(0)
      assert {:error, :invalid_grid} = Grid.random_non_wall_position("a")
      assert {:error, :invalid_grid} = Grid.random_non_wall_position(%{})
      assert {:error, :invalid_grid} = Grid.random_non_wall_position(nil)
    end
  end
end
