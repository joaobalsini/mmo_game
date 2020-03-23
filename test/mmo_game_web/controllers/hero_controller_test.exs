defmodule MmoGameWeb.HeroControllerTest do
  use MmoGameWeb.ConnCase

  test "GET /game redirects to /game?random_name", %{conn: conn} do
    conn = get(conn, "/game")
    "/game?name=" <> hero_name = redir_path = redirected_to(conn)
    assert redir_path == "/game?name=" <> hero_name
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ hero_name
  end

  # didn't have time to add tests for move up, down, left, right and attack
end
