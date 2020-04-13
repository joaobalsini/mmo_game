defmodule MmoGameWeb.HeroController do
  use MmoGameWeb, :controller

  def create(conn, %{"hero" => %{"name" => hero_name}}) do
    updated_hero_name =
      case hero_name do
        "" -> MmoGame.generate_random_name() |> elem(1)
        hero_name -> hero_name
      end

    redirect(conn, to: "/game?name=#{updated_hero_name}")
  end

  def create(conn, _params) do
    {:ok, updated_hero_name} = MmoGame.generate_random_name()
    redirect(conn, to: "/game?name=#{updated_hero_name}")
  end
end
