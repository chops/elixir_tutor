defmodule ElixirTutor.Learning.UserProgress do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_progress" do
    field :completed, :boolean, default: false
    field :completed_at, :utc_datetime

    belongs_to :user, ElixirTutor.Learning.User
    belongs_to :enum_function, ElixirTutor.Learning.EnumFunction

    timestamps()
  end

  @doc false
  def changeset(user_progress, attrs) do
    user_progress
    |> cast(attrs, [:user_id, :enum_function_id, :completed, :completed_at])
    |> validate_required([:user_id, :enum_function_id])
    |> unique_constraint([:user_id, :enum_function_id])
  end
end
