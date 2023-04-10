defmodule TyperaceWeb.JoinLive do
  use TyperaceWeb, :live_view
  alias TyperaceWeb.GameStarter
  alias Typerace.GameServer
  alias Typerace.Player

  @impl true
  def mount(params, _session, socket) do
    code = Map.get(params, "game", "")
    {:ok,
      socket
      |> assign(:changeset, GameStarter.insert_changeset(%{game_code: code}))
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center h-screen">
      <div class="mx-auto text-center justify-center self-center">
      <h1 class="font-bold text-center text-6xl text-white">Join Game</h1>
        <.simple_form
          id="join-game-form"
          for={@changeset}
          :let={f}
          phx-change="validate"
          phx-submit="submit"
          class="mt-14"
        >
          <.input field={f[:name]} label="Player's name:" />
          <.input field={f[:game_code]} label="Code" />
          <.button class="block mt-4 text-center w-full rounded border border-indigo-600 px-12 py-3 text-sm font-medium text-indigo-600 hover:bg-indigo-600 hover:text-white focus:outline-none focus:ring active:bg-indigo-500">
            Join game
          </.button>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"game_starter" => params}, socket) do
    # apply errors to changeset, if any
    changeset =
      params
      |> GameStarter.insert_changeset()
      |> Map.put(:action, :validate)

    # assign changeset in socket
    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("submit", %{"game_starter" => params}, socket) do
    with {:ok, starter} <- GameStarter.create(params),
         {:ok, game_code} <- GameStarter.get_game_code(starter),
         {:ok, player} <- Player.create(%{name: starter.name}),
         {:ok, _} <- GameServer.start_or_join(game_code, player) do
        socket = push_redirect(socket,
          to: Routes.play_path(socket, :index, game: game_code, player: player.id)
        )
        {:noreply, socket}
    else
      {:error, reason} when is_binary(reason) ->
        {:noreply, put_flash(socket, :error, reason)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
