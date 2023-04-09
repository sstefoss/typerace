defmodule Typerace.GameServer do

  use GenServer
  require Logger

  alias Typerace.GameServer
  alias Typerace.GameState
  alias Typerace.Player
  alias Phoenix.PubSub

  def start_link(name, %Player{} = player) do
    case GenServer.start_link(GameServer, %{player: player, code: name}, name: via_tuple(name)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("Already started GameServer #{inspect(name)} at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  def child_spec(opts) do
    name = Keyword.get(opts, :name, GameServer)
    player = Keyword.fetch!(opts, :player)

    %{
      id: "#{GameServer}_#{name}",
      start: {GameServer, :start_link, [name, player]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def start_or_join(game_code, %Player{} = player) do
    Logger.info("start or join server...")
    case Horde.DynamicSupervisor.start_child(
      Typerace.DistributedSupervisor,
      {GameServer, [name: game_code, player: player]}
    ) do
      {:ok, _pid} ->
        Logger.info("Started game server #{inspect(game_code)}")
        {:ok, :started}
      :ignore ->
        Logger.info("Game server #{inspect(game_code)} already running. Joining...")

        case join_game(game_code, player) do
          :ok -> {:ok, :joined}
          {:error, _reason} = error -> error
        end
    end
  end

  def join_game(game_code, %Player{} = player) do
    GenServer.call(via_tuple(game_code), {:join_game, player})
  end

  def get_current_game_state(game_code) do
    GenServer.call(via_tuple(game_code), :current_state)
  end

  def move_forward(game_code, player_id) do
    GenServer.call(via_tuple(game_code), {:move_forward, player_id})
  end

  def start_game(game_code) do
    GenServer.call(via_tuple(game_code), :start_game)
  end

  @impl true
  def handle_call(:current_state, _from, %GameState{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:start_game, _from, %GameState{} = state) do
    with {:ok, started} <- GameState.start(state) do
      broadcast_game_state(started)
      {:reply, :ok, started}

    else
      {:error, reason} ->
        Logger.error("Failed to start game. Error: #{inspect(reason)}")
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:join_game, %Player{} = player }, _from, %GameState{} = state) do
    with {:ok, new_state} <- GameState.join(state, player),
         {:ok, ready} <- GameState.set_ready(new_state) do
          broadcast_game_state(ready)
          {:reply, :ok, ready}
    else
      {:error, reason} ->
        Logger.error("Failed to join and set ready game. Error: #{inspect(reason)}")
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:move_forward, player_id}, _from, %GameState{} = state) do
    with {:ok, player} <- GameState.find_player(state, player_id),
         {:ok, new_state} <- GameState.move_forward(state, player) do
          broadcast_game_state(new_state)
      {:reply, new_state, new_state}
    else
      {:error, reason} = error ->
        Logger.error("Car couldn't move forward. Error: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  def broadcast_game_state(%GameState{} = state) do
    PubSub.broadcast(Typerace.PubSub, "game:#{state.code}", {:game_state, state})
  end

  def generate_game_code() do
    codes = Enum.map([1..3], fn _ -> do_generate_code() end)

    case Enum.find(codes, &(!GameServer.server_found?(&1))) do
      nil ->
        # no unused game code found. Report server busy, try again later.
        {:error, "Didn't find unused code, try again later"}

      code ->
        {:ok, code}
    end
  end

  def do_generate_code() do
    range = ?A..?Z

    1..4
    |> Enum.map(fn _ -> [Enum.random(range)] |> List.to_string() end)
    |> Enum.join("")
  end

  def server_found?(game_code) do
    # Look up the game in the registry. Return if a match is found.
    case Horde.Registry.lookup(Typerace.GameRegistry, game_code) do
      [] -> false
      [{pid, _} | _] when is_pid(pid) -> true
    end
  end

  @impl true
  def init(%{player: player, code: code}) do
    {:ok, GameState.new(code, player)}
  end

  def via_tuple(game_code) do
    {:via, Horde.Registry, {Typerace.GameRegistry, game_code}}
  end
end
