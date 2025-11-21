defmodule ElixirTutor.Learning do
  @moduledoc """
  The Learning context.
  """

  import Ecto.Query, warn: false
  alias ElixirTutor.Repo

  alias ElixirTutor.Learning.{User, EnumFunction, UserProgress, CodeAttempt, UserNote}

  ## User functions

  @doc """
  Gets or creates a user by session_id.
  """
  def get_or_create_user(session_id) do
    case Repo.get_by(User, session_id: session_id) do
      nil ->
        %User{}
        |> User.changeset(%{session_id: session_id})
        |> Repo.insert()

      user ->
        {:ok, user}
    end
  end

  ## EnumFunction functions

  @doc """
  Returns the list of enum_functions.
  """
  def list_enum_functions do
    Repo.all(EnumFunction)
  end

  @doc """
  Gets a single enum_function.
  """
  def get_enum_function!(id), do: Repo.get!(EnumFunction, id)

  @doc """
  Creates an enum_function.
  """
  def create_enum_function(attrs \\ %{}) do
    %EnumFunction{}
    |> EnumFunction.changeset(attrs)
    |> Repo.insert()
  end

  ## UserProgress functions

  @doc """
  Gets user progress for a specific user.
  """
  def get_user_progress(user_id) do
    UserProgress
    |> where([up], up.user_id == ^user_id)
    |> preload(:enum_function)
    |> Repo.all()
  end

  @doc """
  Gets completed function IDs for a user.
  """
  def get_completed_function_ids(user_id) do
    UserProgress
    |> where([up], up.user_id == ^user_id and up.completed == true)
    |> select([up], up.enum_function_id)
    |> Repo.all()
  end

  @doc """
  Gets a random unlearned enum function for the user.
  """
  def get_random_unlearned_function(user_id) do
    completed_ids = get_completed_function_ids(user_id)

    EnumFunction
    |> where([ef], ef.id not in ^completed_ids)
    |> order_by(fragment("RANDOM()"))
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Marks a function as completed for a user.
  """
  def complete_function(user_id, enum_function_id) do
    case Repo.get_by(UserProgress, user_id: user_id, enum_function_id: enum_function_id) do
      nil ->
        %UserProgress{}
        |> UserProgress.changeset(%{
          user_id: user_id,
          enum_function_id: enum_function_id,
          completed: true,
          completed_at: DateTime.utc_now()
        })
        |> Repo.insert()

      progress ->
        progress
        |> UserProgress.changeset(%{completed: true, completed_at: DateTime.utc_now()})
        |> Repo.update()
    end
  end

  ## CodeAttempt functions

  @doc """
  Creates a code attempt.
  """
  def create_code_attempt(attrs \\ %{}) do
    %CodeAttempt{}
    |> CodeAttempt.changeset(attrs)
    |> Repo.insert()
  end

  ## UserNote functions

  @doc """
  Gets or creates a user note for a specific function.
  """
  def get_or_create_user_note(user_id, enum_function_id) do
    case Repo.get_by(UserNote, user_id: user_id, enum_function_id: enum_function_id) do
      nil ->
        %UserNote{}
        |> UserNote.changeset(%{
          user_id: user_id,
          enum_function_id: enum_function_id,
          content: ""
        })
        |> Repo.insert()

      note ->
        {:ok, note}
    end
  end

  @doc """
  Updates a user note.
  """
  def update_user_note(%UserNote{} = note, attrs) do
    note
    |> UserNote.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets all notes for a user with their associated functions.
  """
  def get_user_notes_with_functions(user_id) do
    UserNote
    |> where([un], un.user_id == ^user_id)
    |> preload(:enum_function)
    |> Repo.all()
  end

  @doc """
  Gets the most recent successful code attempt for each completed function.
  Returns a map of enum_function_id => code_attempt.
  """
  def get_completed_attempts(user_id) do
    # Get all completed function IDs
    completed_ids = get_completed_function_ids(user_id)

    # For each completed function, get the most recent successful attempt
    completed_ids
    |> Enum.map(fn function_id ->
      attempt =
        CodeAttempt
        |> where([ca], ca.user_id == ^user_id and ca.enum_function_id == ^function_id and ca.success == true)
        |> order_by([ca], desc: ca.inserted_at)
        |> limit(1)
        |> Repo.one()

      {function_id, attempt}
    end)
    |> Enum.into(%{})
  end
end
