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
      <%= if @server_found do %>
        <%= if @game.status == :not_started do %>
          <div class="mt-8 text-4xl text-gray-700 text-center">
            Waiting for other player to join!
          </div>
          <div class="mt-8 text-8xl text-indigo-700 text-center font-semibold">
            <%= @game.code %>
          </div>
          <p class="mt-2 text-center font-medium text-gray-500">
            Tell a friend to use this game code to join you!
          </p>
        <% else %>
          <%= if @player do %>
            <div class="mb-4 text-lg leading-6 font-medium text-gray-900 text-center">
              Player: <span class="font-semibold"><%= @player.name %></span>
            </div>
          <% end %>
        <% end %>
      <% else %>
        <div class="mt-6">
          <p class="text-center text-4xl text-red-600">
          Connecting to game...
          </p>
          <p class="mt-4 text-center font-medium">
          Did the game you were playing already end?
          </p>
          <div class="mt-6 text-center">
            <%= live_redirect("Start a new game?", to: Routes.page_path(@socket, :index), class: "ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500") %>
          </div>
        </div>
      <% end %>
    """
  end
end
