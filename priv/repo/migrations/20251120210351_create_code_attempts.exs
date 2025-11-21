defmodule ElixirTutor.Repo.Migrations.CreateCodeAttempts do
  use Ecto.Migration

  def change do
    create table(:code_attempts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :enum_function_id, references(:enum_functions, on_delete: :delete_all), null: false
      add :code, :text, null: false
      add :success, :boolean, default: false, null: false
      add :output, :text
      add :error_message, :text

      timestamps()
    end

    create index(:code_attempts, [:user_id])
    create index(:code_attempts, [:enum_function_id])
  end
end
