defmodule MmoGame do
  @moduledoc """
  MmoGame keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def new_with_default_grid() do
    with {:ok, grid} <- MmoGame.Grid.default_grid() do
      MmoGame.GameServer.new(grid)
    end
  end

  defdelegate add_hero(name), to: MmoGame.GameServer
  defdelegate remove_hero(name), to: MmoGame.GameServer

  defdelegate move_hero(name, direction), to: MmoGame.GameServer
  defdelegate attack_from_hero(name), to: MmoGame.GameServer

  def draw_grid() do
    with {:ok, grid} <- MmoGame.GameServer.grid(),
         {:ok, heroes_coordinates} <- MmoGame.GameServer.heroes_coordinates() do
      MmoGame.Grid.draw(grid, heroes_coordinates)
    end
  end

  defdelegate generate_random_name(), to: MmoGame.Utils
end
