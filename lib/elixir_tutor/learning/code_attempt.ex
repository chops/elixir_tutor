defmodule ElixirTutor.Learning.CodeAttempt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "code_attempts" do
    field :code, :string
    field :success, :boolean, default: false
    field :output, :string
    field :error_message, :string

    belongs_to :user, ElixirTutor.Learning.User
    belongs_to :enum_function, ElixirTutor.Learning.EnumFunction

    timestamps()
  end

  @doc false
  def changeset(code_attempt, attrs) do
    code_attempt
    |> cast(attrs, [:user_id, :enum_function_id, :code, :success, :output, :error_message])
    |> validate_required([:user_id, :enum_function_id, :code])
  end
end
