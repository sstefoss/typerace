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

  def start(%GameState{status: :playing}), do: {:error, "Game has started"}
  def start(%GameState{status: :done}), do: {:error, "Game is done"}
  def start(%GameState{status: :not_started, players: [_p1, _p2]} = state) do
    {:ok, %GameState{state | status: :playing}}
  end
  def start(%GameState{players: _players}), do: {:error, "Missing players"}

end
