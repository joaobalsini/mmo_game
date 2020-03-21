defmodule MmoGame.HeroTest do
  use ExUnit.Case
  alias MmoGame.Hero

  describe "new/2" do
    test "starts hero properly in position" do
      hero_name = "Hero1"
      hero_position = {1, 1}

      assert {:ok, :hero_started} == Hero.new(%{name: hero_name, position: hero_position})

      assert {:ok, hero_position} == Hero.where(hero_name)
    end

    test "starting hero with same name returns {:error, :hero_already_exists}" do
      hero_name = "Hero1"
      hero_position = {1, 1}

      assert {:ok, :hero_started} == Hero.new(%{name: hero_name, position: hero_position})

      assert {:error, :hero_already_exists} ==
               Hero.new(%{name: hero_name, position: hero_position})
    end
  end

  describe "started?/1" do
    test "checks if hero is started properly" do
      hero_name = "Hero1"
      hero_position = {1, 1}

      assert {:ok, :hero_started} == Hero.new(%{name: hero_name, position: hero_position})

      assert {:ok, :hero_started} == Hero.started?(hero_name)
      assert {:error, :hero_not_started} == Hero.started?("RANDOM NAME")
    end
  end

  describe "move/2" do
    test "moves hero to position" do
      hero_name = "Hero1"
      hero_position = {1, 1}

      assert {:ok, :hero_started} == Hero.new(%{name: hero_name, position: hero_position})

      assert {:ok, hero_position} == Hero.where(hero_name)

      move_position = {2, 1}
      assert {:ok, :moved} == Hero.move(hero_name, move_position)
      assert {:ok, move_position} == Hero.where(hero_name)
    end
  end

  describe "kill/2" do
    test "kills a hero if not dead" do
      hero_name = "Hero1"
      hero_position = {1, 1}
      respawn_position = {0, 0}

      assert {:ok, :hero_started} == Hero.new(%{name: hero_name, position: hero_position})

      assert {:ok, :hero_alive} == Hero.dead(hero_name)

      assert {:ok, :killed} == Hero.kill(hero_name, respawn_position)
      assert {:ok, :hero_dead} == Hero.dead(hero_name)
    end

    test "returns {:error, :already_dead} if kills a hero that is currently dead" do
      hero_name = "Hero1"
      hero_position = {1, 1}
      respawn_position = {0, 0}

      assert {:ok, :hero_started} == Hero.new(%{name: hero_name, position: hero_position})

      assert {:ok, :hero_alive} == Hero.dead(hero_name)

      assert {:ok, :killed} == Hero.kill(hero_name, respawn_position)
      assert {:ok, :hero_dead} == Hero.dead(hero_name)
      assert {:error, :already_dead} == Hero.kill(hero_name, respawn_position)
    end

    test "properly respawns 5 seconds after being killed in the given position" do
      hero_name = "Hero1"
      hero_position = {1, 1}
      respawn_position = {0, 0}

      assert {:ok, :hero_started} == Hero.new(%{name: hero_name, position: hero_position})

      assert {:ok, :hero_alive} == Hero.dead(hero_name)

      assert {:ok, :killed} == Hero.kill(hero_name, respawn_position)
      assert {:ok, :hero_dead} == Hero.dead(hero_name)

      :timer.sleep(5001)

      assert {:ok, :hero_alive} == Hero.dead(hero_name)
      assert {:ok, respawn_position} == Hero.where(hero_name)
    end
  end

  describe "where/1, where!/1, dead/1, dead!/1" do
    setup do
      hero_name = "Hero1"
      hero_position = {1, 1}

      assert {:ok, :hero_started} == Hero.new(%{name: hero_name, position: hero_position})

      {:ok, %{hero_name: hero_name, hero_position: hero_position}}
    end

    test "where/1 returns Hero position on a tuple", %{
      hero_name: hero_name,
      hero_position: hero_position
    } do
      assert {:ok, hero_position} == Hero.where(hero_name)
    end

    test "where!/1 returns Hero position", %{hero_name: hero_name, hero_position: hero_position} do
      assert hero_position == Hero.where!(hero_name)
    end

    test "dead/1 returns Hero if hero is dead or alive on a tuple", %{
      hero_name: hero_name
    } do
      assert {:ok, :hero_alive} == Hero.dead(hero_name)
    end

    test "dead!/1 returns Hero if hero is dead as a boolean", %{
      hero_name: hero_name
    } do
      assert !Hero.dead!(hero_name)
    end
  end
end
