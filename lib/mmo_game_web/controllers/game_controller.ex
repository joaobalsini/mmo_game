defmodule MmoGameWeb.GameController do
  use MmoGameWeb, :controller

  def index(conn, %{"name" => hero_name}) do
    with {:ok, :game_server_started} <- MmoGame.new_with_default_grid(),
         {:ok, :hero_added} <- MmoGame.add_hero(hero_name),
         {:ok, drawn_grid} <- MmoGame.draw_grid() do
      render(conn, "index.html", drawn_grid: drawn_grid, error: nil, hero: hero_name)
    else
      {:error, :hero_already_exists} ->
        # as suggested, both users will be able to control the user
        {:ok, drawn_grid} = MmoGame.draw_grid()
        render(conn, "index.html", drawn_grid: drawn_grid, error: nil, hero: hero_name)

      _othee ->
        render(conn, "index.html", error: "Error drawing the grid")
    end
  end

  def index(conn, _other) do
    with {:ok, :game_server_started} <- MmoGame.new_with_default_grid(),
         {:ok, hero_name} <- MmoGame.generate_random_name(),
         {:ok, :hero_added} <- MmoGame.add_hero(hero_name),
         {:ok, drawn_grid} <- MmoGame.draw_grid() do
      render(conn, "index.html", drawn_grid: drawn_grid, error: nil, hero: hero_name)
    else
      _any -> render(conn, "index.html", error: "Error drawing the grid")
    end
  end
end
