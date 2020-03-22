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
end
