defmodule MmoGame do
  @moduledoc """
  MmoGame keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @spec new_with_default_grid :: {:ok, :game_server_started}
  def new_with_default_grid() do
    with {:ok, grid} <- MmoGame.Grid.default_grid() do
      MmoGame.GameServer.new(grid)
    end
  end

  @spec add_hero(MmoGame.Hero.hero_name()) ::
          {:error, :game_server_not_started | :hero_already_exists} | {:ok, :hero_added}
  defdelegate add_hero(name), to: MmoGame.GameServer

  @spec remove_hero(MmoGame.Hero.hero_name()) ::
          {:error, :game_server_not_started | :hero_not_found} | {:ok, :hero_removed}
  defdelegate remove_hero(name), to: MmoGame.GameServer

  @spec move_hero(MmoGame.Hero.hero_name(), MmoGame.Grid.move_direction()) ::
          {:error,
           :game_server_not_started
           | :hero_dead
           | :hero_not_found
           | :invalid_move
           | :invalid_move_parameters}
          | {:ok, :moved}
  defdelegate move_hero(name, direction), to: MmoGame.GameServer

  @spec attack_from_hero(MmoGame.Hero.hero_name()) ::
          {:error, :game_server_not_started | :hero_dead | :hero_not_found} | {:ok, :attacked}
  defdelegate attack_from_hero(name), to: MmoGame.GameServer

  @spec draw_grid() ::
          {:error, :game_server_not_started | :invalid_grid}
          | {:ok,
             [
               [
                 %{
                   required(:wall) => boolean(),
                   optional(MmoGame.Grid.coordinate()) => [
                     {MmoGame.Hero.hero_name(), :hero_dead | :hero_alive}
                   ]
                 }
               ]
             ]}
  def draw_grid() do
    with {:ok, grid} <- MmoGame.GameServer.grid(),
         {:ok, heroes_coordinates} <- MmoGame.GameServer.heroes_coordinates() do
      MmoGame.Grid.draw(grid, heroes_coordinates)
    end
  end

  @spec generate_random_name :: {:ok, MmoGame.Hero.hero_name()}
  defdelegate generate_random_name(), to: MmoGame.Utils
end
