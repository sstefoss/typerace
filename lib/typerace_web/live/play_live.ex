defmodule TyperaceWeb.PlayLive do
  use TyperaceWeb, :live_view
  alias Typerace.GameServer
  alias Typerace.GameState
  alias Phoenix.PubSub

  require Logger

  @impl true
  def mount(%{"game" => game_code, "player" => player_id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Typerace.PubSub, "game#{game_code}")
      send(self(), :load_game_state)
    end

    {:ok,
      assign(socket,
        game_code: game_code,
        player_id: player_id,
        player: nil,
        game: %GameState{},
        server_found: GameServer.server_found?(game_code)
      )
    }
  end

  @impl true
  def mount(_params, _session, socket) do
    # redirect to / if there are no params passed in url
    {:ok, push_redirect(socket, to: Routes.page_path(socket, :index))}
  end

  @impl true
  def handle_info(:load_game_state, %{assigns: %{
    server_found: true,
    game_code: game_code,
    player_id: player_id}} = socket
  ) do
    Logger.debug("Game server #{inspect(game_code)} is running")

    case GameServer.get_current_game_state(game_code) do
      %GameState{} = game ->
        player = GameState.get_player(game, player_id)
        IO.inspect(player)
        {:noreply, assign(socket, game: game, player: player)}
      error ->
        Logger.error("Failed to load game server state. #{inspect(error)}")
        {:noreply, assign(socket, :server_found, false)}
    end
  end

  def handle_info(:load_game_state, %{assigns: %{game_code: game_code}} = socket) do
    Logger.debug("Game server #{inspect(game_code)} not found")
    {:noreply, assign(socket, :server_found, GameServer.server_found?(game_code))}
  end

  @impl true
  def render(assigns) do
    IO.inspect(assigns)
    ~H"""
      <div>
        <%= if @player do %>
          <%= @player.color %>
        <% end %>
      </div>
    """
  end
end
