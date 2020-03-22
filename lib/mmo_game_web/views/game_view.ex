defmodule MmoGameWeb.GameView do
  use MmoGameWeb, :view

  import MmoGameWeb.LayoutView, only: [classnames: 1]

  def render_coordinate(coordinate_map, actual_hero_name) do
    case Map.get(coordinate_map, :heroes, nil) do
      nil ->
        ~E"""
        <p class="empty">&nbsp;</p>
        """

      list ->
        render_hero_or_enemy(list, actual_hero_name)
    end
  end

  defp render_hero_or_enemy(hero_list, actual_hero_name) do
    hero =
      Enum.find(hero_list, fn {hero_name, _hero_status} ->
        hero_name == actual_hero_name
      end)

    case hero do
      nil ->
        render_enemy(List.first(hero_list))

      hero ->
        render_hero(hero)
    end
  end

  defp render_hero({hero_name, :hero_alive}) do
    ~E"""
    <p class="hero alive"><%= hero_name %></p>
    """
  end

  defp render_hero({hero_name, :hero_dead}) do
    ~E"""
    <p class="hero dead"><%= hero_name %></p>
    """
  end

  defp render_enemy({enemy_name, :hero_alive}) do
    ~E"""
    <p class="enemy alive"><%= enemy_name %></p>
    """
  end

  defp render_enemy({enemy_name, :hero_dead}) do
    ~E"""
    <p class="enemy dead"><%= enemy_name %></p>
    """
  end
end
