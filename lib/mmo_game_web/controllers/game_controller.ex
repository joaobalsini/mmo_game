defmodule MmoGameWeb.GameController do
  use MmoGameWeb, :controller

  def index(conn, _params) do
    with {:ok, grid} <- MmoGame.Grid.default_grid(),
         {:ok, drawn_grid} <- MmoGame.Grid.draw(grid) do
      render(conn, "index.html", drawn_grid: drawn_grid, error: nil)
    else
      _any -> render(conn, "index.html", error: "Error drawing the grid")
    end
  end
end
