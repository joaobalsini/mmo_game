defmodule MmoGame.GameServerTest do
  use ExUnit.Case
  alias MmoGame.GameServer
  alias MmoGame.Grid
  alias MmoGame.Hero

  describe "new/1 and started?/0" do
    test "starts game with given grid" do
      assert {:error, :game_server_not_started} == GameServer.started?()

      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)
      assert {:ok, :game_server_started} == GameServer.started?()
    end

    test "trying to restart a game that already exists just returns the same thing" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)
      assert {:ok, :game_server_started} == GameServer.new(grid)
    end
  end

  describe "add_hero/1" do
    test "adds a new hero if game was started" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:ok, :hero_added} == GameServer.add_hero(hero_name)
    end

    test "returns {:error, :game_server_not_started} if game wasn't started yet" do
      hero_name = "Hero1"
      assert {:error, :game_server_not_started} == GameServer.add_hero(hero_name)
    end

    test "returns {:error, :hero_already_exists} if try to add hero with the same name again" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:ok, :hero_added} == GameServer.add_hero(hero_name)
      assert {:error, :hero_already_exists} == GameServer.add_hero(hero_name)
    end

    test "heroes start on random positions" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero1 = "Hero1"
      assert {:ok, :hero_added} == GameServer.add_hero(hero1)

      hero2 = "Hero2"
      assert {:ok, :hero_added} == GameServer.add_hero(hero2)

      assert Hero.where!(hero1) != Hero.where!(hero2)
    end
  end

  describe "remove_hero/1" do
    test "removes the hero if hero exists" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:ok, :hero_added} == GameServer.add_hero(hero_name)
      assert {:ok, :hero_removed} == GameServer.remove_hero(hero_name)
      assert {:ok, :hero_added} == GameServer.add_hero(hero_name)
    end

    test "returns {:error, :game_server_not_started} if game wasn't started yet" do
      hero_name = "Hero1"
      assert {:error, :game_server_not_started} == GameServer.remove_hero(hero_name)
    end

    test "returns {:error, :hero_not_found} if hero doesn't exist" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:error, :hero_not_found} == GameServer.remove_hero(hero_name)
    end
  end

  describe "move_hero/2" do
    test "moves hero to specified direction (if doesn't have a wall)" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:ok, :hero_added} == GameServer.add_hero(hero_name)

      # move hero mannualy to a position where we can move up
      {:ok, :moved} = Hero.move(hero_name, {2, 2})

      {:ok, :moved} = GameServer.move_hero(hero_name, :up)
      {:ok, {1, 2}} = Hero.where(hero_name)
    end

    test "returns {:error, :invalid_move} if tries to move into a wall" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:ok, :hero_added} == GameServer.add_hero(hero_name)

      # move hero mannualy to a position where he cannot move up
      {:ok, :moved} = Hero.move(hero_name, {1, 1})
      {:error, :invalid_move} = GameServer.move_hero(hero_name, :up)
    end

    test "returns {:error, :game_server_not_started} if game wasn't started yet" do
      hero_name = "Hero1"
      assert {:error, :game_server_not_started} == GameServer.move_hero(hero_name, :up)
    end

    test "returns {:error, :hero_not_found} if hero doesn't exist" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:error, :hero_not_found} == GameServer.move_hero(hero_name, :up)
    end

    test "returns {:error, :hero_dead} if hero is dead" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:ok, :hero_added} == GameServer.add_hero(hero_name)
      assert {:ok, :killed} = Hero.kill(hero_name, {1, 1})

      {:error, :hero_dead} = GameServer.move_hero(hero_name, :up)
    end
  end

  describe "attack_from_hero/1" do
    test "attack from hero kills surround heroes and after 5 seconds they respawn on random positions" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero1 = "Hero1"
      hero2 = "Hero2"
      hero3 = "Hero3"
      hero4 = "Hero4"
      hero5 = "Hero5"
      assert {:ok, :hero_added} == GameServer.add_hero(hero1)
      assert {:ok, :hero_added} == GameServer.add_hero(hero2)
      assert {:ok, :hero_added} == GameServer.add_hero(hero3)
      assert {:ok, :hero_added} == GameServer.add_hero(hero4)
      assert {:ok, :hero_added} == GameServer.add_hero(hero5)

      # position manually heroes 2, 3 and 4 around hero1
      {:ok, :moved} = Hero.move(hero1, {2, 2})
      {:ok, :moved} = Hero.move(hero2, {1, 1})
      {:ok, :moved} = Hero.move(hero3, {1, 2})
      {:ok, :moved} = Hero.move(hero4, {3, 3})

      # position hero5 far from hero1
      {:ok, :moved} = Hero.move(hero5, {3, 4})

      {:ok, :attacked} = GameServer.attack_from_hero(hero1)

      # Verify heroes situation
      assert {:ok, :hero_alive} = Hero.dead(hero1)
      assert {:ok, :hero_dead} = Hero.dead(hero2)
      assert {:ok, :hero_dead} = Hero.dead(hero3)
      assert {:ok, :hero_dead} = Hero.dead(hero4)
      assert {:ok, :hero_alive} = Hero.dead(hero5)

      # sleep 5 seconds
      :timer.sleep(5001)
      assert {:ok, :hero_alive} = Hero.dead(hero2)
      assert {:ok, :hero_alive} = Hero.dead(hero3)
      assert {:ok, :hero_alive} = Hero.dead(hero4)
    end

    test "returns {:error, :game_server_not_started} if game wasn't started yet" do
      hero_name = "Hero1"
      assert {:error, :game_server_not_started} == GameServer.attack_from_hero(hero_name)
    end

    test "returns {:error, :hero_not_found} if hero doesn't exist" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:error, :hero_not_found} == GameServer.attack_from_hero(hero_name)
    end

    test "returns {:error, :hero_dead} if hero is dead" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero_name = "Hero1"
      assert {:ok, :hero_added} == GameServer.add_hero(hero_name)
      assert {:ok, :killed} = Hero.kill(hero_name, {1, 1})

      {:error, :hero_dead} = GameServer.attack_from_hero(hero_name)
    end
  end

  describe "heroes_coordinates/0" do
    test "returns heroes_coordinates properly" do
      {:ok, grid} = Grid.default_grid()
      assert {:ok, :game_server_started} == GameServer.new(grid)

      hero1 = "Hero1"
      hero2 = "Hero2"
      hero3 = "Hero3"
      hero4 = "Hero4"
      hero5 = "Hero5"
      assert {:ok, :hero_added} == GameServer.add_hero(hero1)
      assert {:ok, :hero_added} == GameServer.add_hero(hero2)
      assert {:ok, :hero_added} == GameServer.add_hero(hero3)
      assert {:ok, :hero_added} == GameServer.add_hero(hero4)
      assert {:ok, :hero_added} == GameServer.add_hero(hero5)

      {:ok, :moved} = Hero.move(hero1, {2, 2})
      {:ok, :moved} = Hero.move(hero2, {1, 1})
      {:ok, :moved} = Hero.move(hero3, {1, 1})
      {:ok, :moved} = Hero.move(hero4, {3, 3})
      {:ok, :moved} = Hero.move(hero5, {3, 4})

      assert {:ok,
              %{
                {2, 2} => [{hero1, :hero_alive}],
                {1, 1} => [{hero2, :hero_alive}, {hero3, :hero_alive}],
                {3, 3} => [{hero4, :hero_alive}],
                {3, 4} => [{hero5, :hero_alive}]
              }} == GameServer.heroes_coordinates()

      {:ok, :attacked} = GameServer.attack_from_hero(hero1)

      assert {:ok,
              %{
                {2, 2} => [{hero1, :hero_alive}],
                {1, 1} => [{hero2, :hero_dead}, {hero3, :hero_dead}],
                {3, 3} => [{hero4, :hero_dead}],
                {3, 4} => [{hero5, :hero_alive}]
              }} == GameServer.heroes_coordinates()
    end
  end
end
