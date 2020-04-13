defmodule MmoGameWeb.GameLive do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(
      MmoGameWeb.GameView,
      "index.html",
      assigns
    )
  end

  def mount(%{"name" => hero_name}, _session, socket) do
    with {:ok, :game_server_started} <- MmoGame.new_with_default_grid(),
         {:ok, :hero_added} <- MmoGame.add_hero(hero_name),
         {:ok, drawn_grid} <- MmoGame.draw_grid() do
      socket =
        socket
        |> assign(drawn_grid: drawn_grid)
        |> assign(error: nil)
        |> assign(hero: hero_name)

      {:ok, socket}
    else
      {:error, :hero_already_exists} ->
        # as suggested, both users will be able to control the user
        {:ok, drawn_grid} = MmoGame.draw_grid()

        socket =
          socket
          |> assign(drawn_grid: drawn_grid)
          |> assign(error: nil)
          |> assign(hero: hero_name)

        {:ok, socket}

      _other ->
        socket =
          socket
          |> assign(drawn_grid: nil)
          |> assign(error: "Error drawing the grid")
          |> assign(hero: nil)

        {:ok, socket}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("attack", _params, socket) do
    hero_name = socket.assigns.hero
    MmoGame.attack_from_hero(hero_name)
    {:noreply, update_grid(socket)}
  end

  def handle_event("move", %{"direction" => direction}, socket)
      when direction in ["up", "down", "left", "right"] do
    hero_name = socket.assigns.hero
    MmoGame.move_hero(hero_name, String.to_atom(direction))
    {:noreply, update_grid(socket)}
  end

  def handle_event("keydown", %{"key" => key}, socket)
      when key in ["ArrowLeft", "ArrowDown", "ArrowUp", "ArrowRight"] do
    hero_name = socket.assigns.hero
    MmoGame.move_hero(hero_name, transform_key_in_direction(key))
    {:noreply, update_grid(socket)}
  end

  def handle_event("keydown", %{"key" => key}, socket)
      when key in ["Enter", " "] do
    hero_name = socket.assigns.hero
    MmoGame.attack_from_hero(hero_name)
    {:noreply, update_grid(socket)}
  end

  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  defp transform_key_in_direction("ArrowLeft"), do: :left
  defp transform_key_in_direction("ArrowRight"), do: :right
  defp transform_key_in_direction("ArrowUp"), do: :up
  defp transform_key_in_direction("ArrowDown"), do: :down

  defp update_grid(socket) do
    {:ok, drawn_grid} = MmoGame.draw_grid()
    assign(socket, drawn_grid: drawn_grid)
  end
end
