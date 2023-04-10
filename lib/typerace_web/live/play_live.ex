defmodule TyperaceWeb.PlayLive do
  use TyperaceWeb, :live_view
  alias Typerace.GameServer
  alias Typerace.GameState
  alias Phoenix.PubSub

  import TyperaceWeb.GameComponents
  require Logger

  @impl true
  def mount(%{"game" => game_code, "player" => player_id} = _params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Typerace.PubSub, "game:#{game_code}")
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
  def handle_info({:game_state, %GameState{} = state} = _event, socket) do
    updated_socket =
      socket
        |> clear_flash()
        |> assign(:game, state)

    {:noreply, updated_socket}
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
  def handle_event("key_down", %{"key" => _key}, %{assigns: %{game_code: code, player_id: player_id }} = socket) do
    case GameServer.move_forward(code, player_id) do
      %GameState{} = game ->
        if game.status == :done do
          {:noreply, push_event(socket, "game_ends", %{game_code: code})}
        else
          {:noreply, socket}
        end

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_event("game_starts", _params, %{assigns: %{game_code: code}} = socket) do
    case GameServer.start_game(code) do
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl
  def handle_event("restart", params, %{assigns: %{game_code: code}} = socket) do
    case GameServer.restart(code) do
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  def generate_tree() do
    %{
      width: Enum.random(60..120),
      x: Enum.random(10..90)
    }
  end

  def genererate_trees() do
    Enum.map(1..6, fn _ -> generate_tree() end)
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <%= if @server_found do %>
        <%= if @game.status == :not_started do %>
        <div class="flex items-center h-screen">
          <div class="mx-auto text-center justify-center self-center">
            <div class="mt-8 text-4xl text-white font-bold text-center">
              Waiting for other player to join!
            </div>
            <div class="mt-8 text-8xl text-indigo-700 text-center font-semibold">
              <%= @game.code %>
            </div>
            <p class="mt-2 text-center font-medium text-gray-500">
              <a href={"/join?game=#{@game.code}"}>Share link</a>
            </p>
          </div>
        </div>
        <% else %>
          <%= if @player do %>
            <div>
              <%= if @game.status == :ready do %>
                <div id="countdown" class="absolute left-1/2 transform -translate-x-1/2 drop-shadow-lg top-[10%] z-20 font-bold text-9xl text-white" phx-hook="Countdown">
                  <div id="timer">3</div>
                </div>
              <% end %>

              <%= if @game.status == :playing do %>
                <div id="game_control" phx-hook="GameControl" />
              <% end %>

              <div class="w-full relative h-[200px]">
                <.environment trees={genererate_trees()} />
              </div>
              <div id="game" class="relative w-full h-[200px]">
                <.road />
                <%= for {player, index} <- Enum.with_index(@game.players) do %>
                  <.car
                    id={player.id}
                    color={player.color}
                    x={player.pos}
                    y={if index == 0, do: 20, else: 65}
                  />
                <% end %>
              </div>
              <div class="bg-white bg-opacity-50 py-14 px-28">
                <%= for player <- @game.players do %>
                  <.player
                    name={player.name}
                    color={player.color}
                    is_winner={GameState.is_winner?(@game, player)}
                  />
                <% end %>
              </div>
              <div :if={@game.status == :done}>
                <.button class="block mt-4 text-center w-full rounded border border-indigo-600 px-12 py-3 text-sm font-medium text-indigo-600 hover:bg-indigo-600 hover:text-white focus:outline-none focus:ring active:bg-indigo-500" phx-click="restart">
                  Restart
                </.button>
              </div>
            </div>
          <% end %>
        <% end %>
      <% else %>
        <div class="flex items-center h-screen">
          <div class="mx-auto text-center justify-center self-center">
            <p class="text-center text-4xl text-red-600">
            Connecting to game...
            </p>
            <p class="mt-4 text-center font-medium">
            Did the game you were playing already end?
            </p>
            <div class="mt-10 text-center">
              <%= live_redirect("Create a new game", to: Routes.create_path(@socket, :index), class: "block text-center w-full rounded text-xl font-medium hover:font-bold text-white hover:text-white focus:outline-none focus:ring") %>
            </div>
          </div>
        </div>
      <% end %>
    """
  end
end
