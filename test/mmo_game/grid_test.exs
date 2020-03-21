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

  describe("draw/2") do
    setup do
      walls = [{0, 0}, {0, 9}, {9, 0}]
      rows = 10
      columns = 10

      {:ok, grid} =
        Grid.new(%{
          rows: rows,
          columns: columns,
          walls: walls
        })

      heroes_coordinates = %{
        {1, 1} => [{"Hero1", :hero_alive}],
        {1, 2} => [{"Hero2", :hero_alive}, {"Hero3", :hero_dead}]
      }

      {:ok, %{grid: grid, heroes_coordinates: heroes_coordinates}}
    end

    test "draws a valid grid properly", %{grid: grid, heroes_coordinates: heroes_coordinates} do
      assert {:ok, drawn_grid} = Grid.draw(grid, heroes_coordinates)

      Enum.each(0..(grid.rows - 1), fn row ->
        Enum.each(0..(grid.columns - 1), fn column ->
          element =
            drawn_grid
            |> Enum.at(row)
            |> Enum.at(column)

          case {Map.get(grid.walls, {row, column}, false), {row, column}} do
            {true, _any} ->
              assert element == %{wall: true}

            {false, {1, 1}} ->
              assert element == %{wall: false, heroes: [{"Hero1", :hero_alive}]}

            {false, {1, 2}} ->
              assert element == %{
                       wall: false,
                       heroes: [{"Hero2", :hero_alive}, {"Hero3", :hero_dead}]
                     }

            {false, _other} ->
              assert element == %{wall: false}
          end
        end)
      end)
    end

    test "returns {:error, :invalid_grid} if passed params is not a grid or valid_heroes_coordinates",
         %{grid: valid_grid, heroes_coordinates: valid_heroes_coordinates} do
      assert {:error, :invalid_grid} = Grid.draw(0, valid_heroes_coordinates)
      assert {:error, :invalid_grid} = Grid.draw("a", valid_heroes_coordinates)
      assert {:error, :invalid_grid} = Grid.draw(%{}, valid_heroes_coordinates)
      assert {:error, :invalid_grid} = Grid.draw(nil, valid_heroes_coordinates)

      assert {:error, :invalid_grid} = Grid.draw(valid_grid, [])
      assert {:error, :invalid_grid} = Grid.draw(valid_grid, 1)
      assert {:error, :invalid_grid} = Grid.draw(valid_grid, {})
      assert {:error, :invalid_grid} = Grid.draw(valid_grid, nil)
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

  describe "can_move/3" do
    setup do
      walls = [{0, 0}, {0, 9}, {9, 0}]
      rows = 10
      columns = 10

      {:ok, grid} =
        Grid.new(%{
          rows: rows,
          columns: columns,
          walls: walls
        })

      {:ok, %{grid: grid}}
    end

    test "calculates moves properly to all directions", %{grid: grid} do
      assert {:ok, {1, 2}} == Grid.can_move?(grid, {2, 2}, :up)
      assert {:ok, {2, 3}} == Grid.can_move?(grid, {2, 2}, :right)
      assert {:ok, {3, 2}} == Grid.can_move?(grid, {2, 2}, :down)
      assert {:ok, {2, 1}} == Grid.can_move?(grid, {2, 2}, :left)
    end

    test "returns {:error, :invalid_move} if moves into wall", %{grid: grid} do
      assert {:error, :invalid_move} == Grid.can_move?(grid, {1, 0}, :up)
      assert {:error, :invalid_move} == Grid.can_move?(grid, {0, 8}, :right)
      assert {:error, :invalid_move} == Grid.can_move?(grid, {8, 0}, :down)
      assert {:error, :invalid_move} == Grid.can_move?(grid, {9, 1}, :left)
    end
  end

  describe "calculate_perimeter/2" do
    setup do
      walls = [{0, 0}, {0, 9}, {9, 0}]
      rows = 10
      columns = 10

      {:ok, grid} =
        Grid.new(%{
          rows: rows,
          columns: columns,
          walls: walls
        })

      {:ok, %{grid: grid}}
    end

    test "calculates perimeter of coordinate properly, not showing walls", %{grid: grid} do
      assert [
               {1, 2},
               {1, 3},
               {2, 3},
               {3, 3},
               {3, 2},
               {3, 1},
               {2, 1},
               {1, 1}
             ] == Grid.calculate_perimeter!(grid, {2, 2})

      assert [
               {0, 1},
               {0, 2},
               {1, 2},
               {2, 2},
               {2, 1},
               {2, 0},
               {1, 0}
             ] == Grid.calculate_perimeter!(grid, {1, 1})
    end
  end
end
