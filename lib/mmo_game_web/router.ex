defmodule MmoGameWeb.Router do
  use MmoGameWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MmoGameWeb do
    pipe_through :browser

    get "/", PageController, :index

    resources "/game", GameController, only: [:index]

    resources "/hero", HeroController, only: [:create] do
      post "/move_up", HeroController, :move_up, as: :move_up
      post "/move_down", HeroController, :move_down, as: :move_down
      post "/move_left", HeroController, :move_left, as: :move_left
      post "/move_right", HeroController, :move_right, as: :move_right
      post "/attack", HeroController, :attack, as: :attack
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MmoGameWeb do
  #   pipe_through :api
  # end
end
