defmodule MmoGame.Hero do
  @moduledoc """
  Defines a Hero.

  Hero is a genserver and keeps his own state using %Hero{} struct.
  """

  @enforce_keys [:id, :name, :position, :dead]
  defstruct @enforce_keys

  use GenServer

  @type id :: {atom(), binary()}
  @type hero_name :: binary()
  @type t :: %__MODULE__{
          id: id(),
          name: hero_name(),
          position: MmoGame.Grid.coordinate(),
          dead: boolean()
        }

  ##################
  # API
  ##################
  @spec new(%{name: hero_name(), position: MmoGame.Grid.coordinate()}) ::
          {:ok, :hero_started} | {:error, :hero_already_exists}
  def new(%{name: name, position: _position} = params) do
    id = String.to_atom(name)
    hero = struct(__MODULE__, Map.merge(params, %{dead: false, id: id}))

    case GenServer.start_link(__MODULE__, hero, name: id) do
      {:ok, _pid} ->
        {:ok, :hero_started}

      {:error, {:already_started, _pid}} ->
        {:error, :hero_already_exists}
    end
  end

  @spec started?(hero_name()) :: {:error, :hero_not_started} | {:ok, :hero_started}
  def started?(name) do
    case Process.whereis(String.to_atom(name)) do
      nil -> {:error, :hero_not_started}
      _pid -> {:ok, :hero_started}
    end
  end

  @spec move(hero_name(), MmoGame.Grid.coordinate()) ::
          {:error, :hero_not_started} | {:ok, :moved}
  def move(name, {_new_row, _new_col} = new_position) do
    with {:ok, :hero_started} <- started?(name) do
      GenServer.call(String.to_atom(name), {:move, new_position})
    end
  end

  @spec kill(hero_name(), MmoGame.Grid.coordinate()) ::
          {:error, :hero_not_started} | {:error, :already_dead} | {:ok, :killed}
  def kill(name, respawn_position) do
    with {:ok, :hero_started} <- started?(name) do
      GenServer.call(String.to_atom(name), {:kill, respawn_position})
    end
  end

  @spec where(hero_name()) :: {:ok, MmoGame.Grid.coordinate()} | {:error, :hero_not_started}
  def where(name) do
    with {:ok, :hero_started} <- started?(name) do
      GenServer.call(String.to_atom(name), :where)
    end
  end

  @spec where!(hero_name()) :: MmoGame.Grid.coordinate() | no_return()
  def where!(name) do
    GenServer.call(String.to_atom(name), :where!)
  end

  @spec dead(hero_name()) :: {:ok, :hero_alive} | {:ok, :hero_dead}
  def dead(name) do
    with {:ok, :hero_started} <- started?(name) do
      GenServer.call(String.to_atom(name), :dead)
    end
  end

  @spec dead!(hero_name()) :: :hero_alive | :hero_dead | no_return()
  def dead!(name) do
    GenServer.call(String.to_atom(name), :dead!)
  end

  ##################
  # SERVER CALLBACKS
  ##################

  @impl true
  @doc false
  def init(%__MODULE__{} = hero) do
    {:ok, hero}
  end

  @impl true
  @doc false
  def handle_call(
        {:move, new_position},
        _from,
        %__MODULE__{} = hero
      ),
      do: {:reply, {:ok, :moved}, Map.put(hero, :position, new_position)}

  @impl true
  @doc false
  def handle_call({:kill, respawn_position}, _from, %__MODULE__{dead: false} = hero) do
    updated_hero = Map.put(hero, :dead, true)
    schedule_respawn(respawn_position)
    {:reply, {:ok, :killed}, updated_hero}
  end

  @impl true
  @doc false
  def handle_call({:kill, _respawn_position}, _from, %__MODULE__{dead: true} = hero),
    do: {:reply, {:error, :already_dead}, hero}

  @impl true
  @doc false
  def handle_call(:dead, _from, %__MODULE__{dead: true} = hero),
    do: {:reply, {:ok, :hero_dead}, hero}

  @impl true
  @doc false
  def handle_call(:dead, _from, %__MODULE__{dead: false} = hero),
    do: {:reply, {:ok, :hero_alive}, hero}

  @impl true
  @doc false
  def handle_call(:dead!, _from, %__MODULE__{dead: dead} = hero),
    do: {:reply, dead, hero}

  @impl true
  @doc false
  def handle_call(:where, _from, %__MODULE__{position: position} = hero),
    do: {:reply, {:ok, position}, hero}

  @impl true
  @doc false
  def handle_call(:where!, _from, %__MODULE__{position: position} = hero),
    do: {:reply, position, hero}

  @impl true
  @doc false
  def handle_info({:respawn, respawn_position}, %__MODULE__{} = hero),
    do: {:noreply, Map.merge(hero, %{dead: false, position: respawn_position})}

  defp schedule_respawn(respawn_position),
    do: Process.send_after(self(), {:respawn, respawn_position}, 5 * 1000)
end
