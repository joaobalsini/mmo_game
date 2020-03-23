defmodule MmoGameWeb.PageControllerTest do
  use MmoGameWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Write your name to start"
  end

  test "Typing the user and clicking start redirects to game", %{conn: conn} do
    conn = post(conn, Routes.hero_path(conn, :create, %{hero: %{name: "heroname"}}))

    redir_path = redirected_to(conn)
    assert redir_path == "/game?name=heroname"
    conn = get(recycle(conn), redir_path)

    assert html_response(conn, 200) =~ "heroname"
  end
end
