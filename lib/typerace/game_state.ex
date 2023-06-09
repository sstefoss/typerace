defmodule Typerace.GameState do
  alias Typerace.GameState
  alias Typerace.Player

  defstruct code: nil,
            players: [],
            status: :not_started

  def new(code, player) do
    %GameState{code: code, players: [%Player{player | color: "blue"}]}
  end

  def join(%GameState{players: [_p1, _p2]} = _state, %Player{}) do
    {:error, "Only 2 players are allowed"}
  end

  def join(%GameState{players: []}, %Player{}) do
    {:error, "Can only join a created game"}
  end

  def join(%GameState{players: [p1]} = state, %Player{} = player) do
    player =
      if p1.color == "blue" do
        %Player{player | color: "red"}
      else
        %Player{player | color: "blue"}
      end

    {:ok, %GameState{state | players: [p1, player]}}
  end

  def restart(%GameState{players: [p1, p2]} = state) do
    with {:ok, p1_blank} <- Player.create(%{name: p1.name, color: p1.color, id: p1.id }),
         {:ok, p2_blank} <- Player.create(%{name: p2.name, color: p2.color, id: p2.id }) do
      {:ok, %GameState{state | status: :ready, players: [p1_blank, p2_blank]}}
    else
      :error -> {:error, "Could not restart game"}
    end
  end

  def start(%GameState{status: :playing}), do: {:error, "Game has started"}
  def start(%GameState{status: :not_started}), do: {:error, "Game is not ready"}
  def start(%GameState{status: :done}), do: {:error, "Game is done"}
  def start(%GameState{status: :ready, players: [_p1, _p2]} = state) do
    {:ok, %GameState{state | status: :playing}}
  end
  def start(%GameState{players: _players}), do: {:error, "Missing players"}

  def set_ready(%GameState{status: :playing}), do: {:error, "Game has started"}
  def set_ready(%GameState{status: :ready}), do: {:error, "Game is already ready"}
  def set_ready(%GameState{status: :done}), do: {:error, "Game is done"}
  def set_ready(%GameState{status: :not_started, players: [_p1, _p2]} = state) do
    {:ok, %GameState{state | status: :ready}}
  end
  def set_ready(%GameState{players: _players}), do: {:error, "Missing players"}

  def get_player(%GameState{players: players} = _state, player_id) do
    Enum.find(players, &(&1.id == player_id))
  end

  def move_forward(%GameState{status: :playing} = state, %Player{} = player) do
    state
    |> player_move_forward(player)
    |> check_for_done()
  end


  def move_forward(%GameState{status: :not_started} = _state, %Player{} = _player) do
    {:error, "Game hasn't started yet"}
  end

  def move_forward(%GameState{status: :done} = _state, %Player{} = _player) do
    {:error, "Game is over"}
  end

  def find_player(%GameState{} = state, player_id) do
    case get_player(state, player_id) do
      nil ->
        {:error, "Player not found"}

      %Player{} = player ->
        {:ok, player}
    end
  end

  defp player_move_forward(%GameState{players: players} = state, %Player{id: player_id} = _player) do
    updated_players = Enum.map(players, fn p ->
      if (p.id == player_id) do
        %{p | pos: p.pos + 1}
      else p
      end
    end)

    {:ok, %GameState{state | players: updated_players }}
  end

  defp check_for_done({:ok, state}) do
    case result(state) do
      :playing ->
        {:ok, state}
      _ ->
        {:ok, %GameState{state | status: :done}}
    end
  end

  def result(%GameState{players: [p1, p2]} = _state) do
    player_1_won = p1.pos == 100
    player_2_won = p2.pos == 100

    cond do
      player_1_won -> p1
      player_2_won -> p2
      true -> :playing
    end
  end

  def is_winner?(%GameState{} = game, %Player{} = player) do
    case GameState.result(game) do
      ^player -> true
      _ -> false
    end
  end
end
