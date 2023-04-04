defmodule TyperaceWeb.GameStarter do
  use Ecto.Schema
  import Ecto.Changeset
  alias TyperaceWeb.GameStarter
  alias Typerace.GameServer

  embedded_schema do
    field :name, :string
    field :game_code, :string
    field :type, Ecto.Enum, values: [:start, :join], default: :start
  end

  def insert_changeset(attrs) do
    changeset = %GameStarter{}
    |> cast(attrs, [:name, :game_code])
    |> validate_required([:name])
    |> validate_length(:name, max: 15)
    |> validate_length(:game_code, is: 4)
    |> uppercase_game_code()
    |> validate_game_code()
    |> compute_type()

    changeset
  end

  def uppercase_game_code(changeset) do
    case get_field(changeset, :game_code) do
      nil -> changeset
      value -> put_change(changeset, :game_code, String.upcase(value))
    end
  end

  def compute_type(changeset) do
    case get_field(changeset, :game_code) do
      nil -> put_change(changeset, :type, :start)
      _ -> put_change(changeset, :type, :join)
    end
  end

  def get_game_code(%GameStarter{type: :join, game_code: code}), do: {:ok, code}
  def get_game_code(%GameStarter{type: :start}) do
    {:ok, GameServer.generate_game_code()}
  end

  def validate_game_code(changeset) do
    if changeset.errors[:game_code] do
      changeset
    else
      case get_field(changeset, :game_code) do
        nil ->
          changeset

        value ->
          if GameServer.server_found?(value) do
            changeset
          else
            add_error(changeset, :game_code, "Not a running game")
          end
      end
    end
  end

  def create(params) do
    params
    |> insert_changeset()
    |> apply_action(:insert)
  end
end
