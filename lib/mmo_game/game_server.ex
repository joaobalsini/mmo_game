defmodule MmoGame.GameServer do
  use GenServer

  @moduledoc """
  Manages players
  """

  @enforce_keys [:grid, :heroes]
  defstruct @enforce_keys

  alias MmoGame.Hero
  alias MmoGame.Grid

  @type t :: %__MODULE__{
          grid: Grid.t(),
          heroes: [Hero.t()]
        }

  @id __MODULE__

  ##################
  # API
  ##################

  @spec new(MmoGame.Grid.t()) :: {:ok, :game_server_started}

  @doc """
  Starts a game with a given grid.

  Since we only have one game on the server, whenever someone tries to do anything, we just try to start it again.

  If it's already started, it will just return {:ok, :game_server_started} without changing anything.
  """
  def new(%Grid{} = grid) do
    GenServer.start_link(__MODULE__, grid, name: __MODULE__)
    {:ok, :game_server_started}
  end

  @spec started? :: {:error, :game_server_not_started} | {:ok, :game_server_started}
  def started?() do
    case Process.whereis(@id) do
      nil -> {:error, :game_server_not_started}
      _pid -> {:ok, :game_server_started}
    end
  end

  @spec add_hero(Hero.hero_name()) ::
          {:ok, :hero_added}
          | {:error, :game_server_not_started}
          | {:error, :hero_already_exists}
  def add_hero(name) do
    with {:ok, :game_server_started} <- started?(),
         {:ok, :can_add_hero} <- can_add_hero?(name),
         {:ok, grid} <- grid(),
         {:ok, spawn_position} <- Grid.random_non_wall_position(grid),
         {:ok, :hero_started} <- Hero.new(%{name: name, position: spawn_position}) do
      GenServer.call(@id, {:add_hero, name})
    end
  end

  @spec remove_hero(Hero.hero_name()) ::
          {:ok, :hero_removed}
          | {:error, :game_server_not_started}
          | {:error, :hero_not_found}
  def remove_hero(name) do
    with {:ok, :game_server_started} <- started?(),
         {:ok, hero_name} <- find_hero(name),
         {:ok, :hero_stopped} <- Hero.stop(hero_name) do
      GenServer.call(@id, {:remove_hero, hero_name})
    end
  end

  @spec move_hero(Hero.hero_name(), Grid.move_direction()) ::
          {:ok, :moved}
          | {:error, :game_server_not_started}
          | {:error, :hero_not_found}
          | {:error, :hero_dead}
          | {:error, :invalid_move}
          | {:error, :invalid_move_parameters}
  def move_hero(name, direction) when direction in [:up, :down, :left, :right] do
    with {:ok, :game_server_started} <- started?(),
         {:ok, hero_name} <- find_hero(name),
         {:ok, :hero_alive} <- Hero.dead(hero_name),
         {:ok, actual_position} <- Hero.where(hero_name),
         {:ok, grid} <- grid(),
         {:ok, new_position} <- Grid.can_move?(grid, actual_position, direction) do
      Hero.move(name, new_position)
    else
      {:ok, :hero_dead} -> {:error, :hero_dead}
      other -> other
    end
  end

  def move_hero(_, _), do: {:error, :invalid_move}

  @spec attack_from_hero(Hero.hero_name()) ::
          {:ok, :attacked}
          | {:error, :game_server_not_started}
          | {:error, :hero_not_found}
          | {:error, :hero_dead}
  def attack_from_hero(name) do
    with {:ok, :game_server_started} <- started?(),
         {:ok, grid} <- grid(),
         {:ok, hero_name} <- find_hero(name),
         {:ok, :hero_alive} <- Hero.dead(hero_name),
         {:ok, hero_position} <- Hero.where(hero_name),
         {:ok, heroes} <- heroes() do
      attack_range = Grid.calculate_perimeter!(grid, hero_position)

      # Check if all heroes exist, if not, restart process
      Enum.each(heroes, &find_hero(&1))

      heroes
      |> Enum.filter(&(&1 != name))
      |> Enum.filter(&(Hero.where!(&1) in attack_range))
      |> Enum.each(&kill_hero/1)

      {:ok, :attacked}
    else
      {:ok, :hero_dead} -> {:error, :hero_dead}
      other -> other
    end
  end

  defp kill_hero(name) do
    with {:ok, :game_server_started} <- started?(),
         {:ok, grid} <- grid(),
         {:ok, respawn_position} <-
           Grid.random_non_wall_position(grid),
         {:ok, hero_name} <- find_hero(name) do
      Hero.kill(hero_name, respawn_position)
    end
  end

  @spec heroes_coordinates ::
          {:ok, %{optional(Grid.coordinate()) => [{Hero.hero_name(), :hero_alive | :hero_dead}]}}
          | {:error, :game_server_not_started}
  @doc """
  Asks all heroes their positions and combines than in a map where the keys are coordinates and values are lists of heroes on those coordinates

  Returns something like:
  ```
  {:ok, %{ {1,1} => [{"Hero1",:hero_alive}, {"Hero2", :hero_alive}], {2,2} => [{"Hero3", :hero_dead}] }}
  ```

  or {:error, :game_server_not_started} if server wasn't started
  """
  def heroes_coordinates() do
    with {:ok, :game_server_started} <- started?(),
         {:ok, heroes} <- heroes() do
      # check if any heroes process were killed and restart them if needed
      Enum.each(heroes, &find_hero(&1))

      map_of_heroes_coordinates =
        heroes
        |> Enum.map(&{&1, Hero.where!(&1), Hero.dead!(&1)})
        |> Enum.reduce(%{}, fn {hero_name, hero_coordinate, hero_status}, acc ->
          Map.update(acc, hero_coordinate, [{hero_name, hero_status}], fn list ->
            [{hero_name, hero_status} | list]
          end)
        end)

      {:ok, map_of_heroes_coordinates}
    end
  end

  @spec grid() ::
          {:ok, Grid.t()}
          | {:error, :game_server_not_started}
  def grid() do
    with {:ok, :game_server_started} <- started?() do
      GenServer.call(@id, :grid)
    end
  end

  defp heroes() do
    GenServer.call(@id, :heroes)
  end

  # If hero exists on list but crashed, we restart the process here
  defp find_hero(name) do
    with {:ok, :game_server_started} <- started?(),
         {:ok, heroes} <- heroes(),
         hero_name when is_binary(hero_name) <-
           Enum.find(heroes, &(&1 == name)),
         {:ok, :hero_started} <- Hero.started?(hero_name) do
      {:ok, hero_name}
    else
      nil ->
        {:error, :hero_not_found}

      {:error, :hero_not_started} ->
        # when we have this error, it means we need to restart the hero process
        restart_hero_process(name)

      {:error, any} ->
        {:error, any}
    end
  end

  defp restart_hero_process(name) do
    {:ok, grid} = grid()
    {:ok, spawn_position} = Grid.random_non_wall_position(grid)
    Hero.new(%{name: name, position: spawn_position})
  end

  defp can_add_hero?(name) do
    case find_hero(name) do
      {:error, :hero_not_found} -> {:ok, :can_add_hero}
      {:ok, _hero_name} -> {:error, :hero_already_exists}
      {:error, other} -> {:error, other}
    end
  end

  def reset_heroes() do
    GenServer.call(@id, :reset_heroes)
  end

  ##################
  # DEFINE AUTOSTART
  # WHEN APP STARTS
  ##################
  def start_link(_) do
    with {:ok, grid} <- Grid.default_grid() do
      ets_heroes = :ets.lookup(:game_server_backup, :heroes)

      heroes =
        case ets_heroes do
          [] -> []
          [{_key, list}] -> list
        end

      GenServer.start_link(__MODULE__, %{grid: grid, heroes: heroes}, name: __MODULE__)
    end
  end

  ##################
  # SERVER CALLBACKS
  ##################

  @impl true
  @doc false
  def init(%Grid{} = grid) do
    game_server = struct(__MODULE__, %{grid: grid, heroes: []})
    {:ok, game_server}
  end

  @impl true
  @doc false
  def init(%{grid: %Grid{} = grid, heroes: heroes}) do
    game_server = struct(__MODULE__, %{grid: grid, heroes: heroes})
    {:ok, game_server}
  end

  @impl true
  @doc false
  def handle_call({:add_hero, name}, _from, %__MODULE__{heroes: current_heroes} = state) do
    updated_heroes = [name | current_heroes]
    :ets.insert(:game_server_backup, {:heroes, updated_heroes})

    {:reply, {:ok, :hero_added}, Map.put(state, :heroes, updated_heroes)}
  end

  @impl true
  @doc false
  def handle_call(
        {:remove_hero, name},
        _from,
        %__MODULE__{heroes: current_heroes} = state
      ) do
    updated_heroes = List.delete(current_heroes, name)
    :ets.insert(:game_server_backup, {:heroes, updated_heroes})
    {:reply, {:ok, :hero_removed}, Map.put(state, :heroes, updated_heroes)}
  end

  @impl true
  @doc false
  def handle_call(:state, _from, state), do: {:reply, {:ok, state}, state}

  @impl true
  @doc false
  def handle_call(:reset_heroes, _from, state),
    do: {:reply, {:ok, :reset}, Map.put(state, :heroes, [])}

  @impl true
  @doc false
  def handle_call(:grid, _from, %__MODULE__{grid: grid} = state), do: {:reply, {:ok, grid}, state}

  @impl true
  @doc false
  def handle_call(:heroes, _from, %__MODULE__{heroes: heroes} = state),
    do: {:reply, {:ok, heroes}, state}
end
