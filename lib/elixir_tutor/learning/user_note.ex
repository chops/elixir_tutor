defmodule ElixirTutor.Learning.UserNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_notes" do
    field :content, :string

    belongs_to :user, ElixirTutor.Learning.User
    belongs_to :enum_function, ElixirTutor.Learning.EnumFunction

    timestamps()
  end

  @doc false
  def changeset(user_note, attrs) do
    user_note
    |> cast(attrs, [:user_id, :enum_function_id, :content])
    |> validate_required([:user_id, :enum_function_id])
    |> unique_constraint([:user_id, :enum_function_id])
  end
end
