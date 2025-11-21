defmodule ElixirTutor.Learning.EnumFunction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "enum_functions" do
    field :name, :string
    field :arity, :integer
    field :documentation, :string
    field :examples, :string

    has_many :user_progress, ElixirTutor.Learning.UserProgress
    has_many :code_attempts, ElixirTutor.Learning.CodeAttempt
    has_many :user_notes, ElixirTutor.Learning.UserNote

    timestamps()
  end

  @doc false
  def changeset(enum_function, attrs) do
    enum_function
    |> cast(attrs, [:name, :arity, :documentation, :examples])
    |> validate_required([:name, :arity])
    |> unique_constraint([:name, :arity])
  end
end
