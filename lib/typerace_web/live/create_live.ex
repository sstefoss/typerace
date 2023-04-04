defmodule TyperaceWeb.CreateLive do
  use TyperaceWeb, :live_view
  alias Typerace.GameServer
  alias TyperaceWeb.GameStarter
  alias Typerace.Player

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign(:changeset, GameStarter.insert_changeset(%{}))
    }
  end

  @impl true
  def handle_event("validate", %{"game_starter" => params}, socket) do
    changeset =
      params
      |> GameStarter.insert_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

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

  @impl true
  def render(assigns) do
    ~H"""
      <h1 class="font-bold text-center text-2xl">Create a TypeRace</h1>
      <.simple_form
        id="create-game-form"
        for={@changeset}
        :let={f}
        phx-change="validate"
        phx-submit="submit"
      >
        <.input field={f[:name]} label="Name" />
        <.button class="block mt-4 text-center w-full rounded border border-indigo-600 px-12 py-3 text-sm font-medium text-indigo-600 hover:bg-indigo-600 hover:text-white focus:outline-none focus:ring active:bg-indigo-500">
          Create
        </.button>
      </.simple_form>
    """
  end
end
