defmodule Typerace.Player do
  use Ecto.Schema
  import Ecto.Changeset

  alias Typerace.Player

  embedded_schema do
    field :name, :string
    field :color, :string
  end

  def insert_changeset(attrs) do
    %Player{}
      |> cast(attrs, [:name, :color])
      |> validate_required([:name])
      |> generate_id()
  end

  def generate_id(changeset) do
    case get_field(changeset, :id) do
      nil -> put_change(changeset, :id, Ecto.UUID.generate())
      _ -> changeset
    end
  end

  def create(params) do
    params
    |> insert_changeset()
    |> apply_action(:insert)
  end

end
