defmodule ElixirTutor.Learning.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :session_id, :string

    has_many :user_progress, ElixirTutor.Learning.UserProgress
    has_many :code_attempts, ElixirTutor.Learning.CodeAttempt
    has_many :user_notes, ElixirTutor.Learning.UserNote

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:session_id])
    |> validate_required([:session_id])
    |> unique_constraint(:session_id)
  end
end
