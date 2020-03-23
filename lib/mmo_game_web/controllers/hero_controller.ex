defmodule MmoGameWeb.HeroController do
  use MmoGameWeb, :controller

  def move_up(conn, %{"hero_id" => hero_name}) do
    MmoGame.move_hero(hero_name, :up)
    redirect(conn, to: "/game?name=#{hero_name}")
  end

  def move_down(conn, %{"hero_id" => hero_name}) do
    MmoGame.move_hero(hero_name, :down)
    redirect(conn, to: "/game?name=#{hero_name}")
  end

  def move_left(conn, %{"hero_id" => hero_name}) do
    MmoGame.move_hero(hero_name, :left)
    redirect(conn, to: "/game?name=#{hero_name}")
  end

  def move_right(conn, %{"hero_id" => hero_name}) do
    MmoGame.move_hero(hero_name, :right)
    redirect(conn, to: "/game?name=#{hero_name}")
  end

  def attack(conn, %{"hero_id" => hero_name}) do
    MmoGame.attack_from_hero(hero_name)
    redirect(conn, to: "/game?name=#{hero_name}")
  end

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
