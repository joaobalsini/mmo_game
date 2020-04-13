defmodule MmoGameWeb.Router do
  use MmoGameWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {MmoGameWeb.LayoutView, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MmoGameWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/hero", HeroController, only: [:create]
    live "/game", GameLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", MmoGameWeb do
  #   pipe_through :api
  # end
end
