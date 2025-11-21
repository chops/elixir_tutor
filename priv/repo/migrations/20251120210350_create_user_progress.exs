defmodule ElixirTutor.Repo.Migrations.CreateUserProgress do
  use Ecto.Migration

  def change do
    create table(:user_progress) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :enum_function_id, references(:enum_functions, on_delete: :delete_all), null: false
      add :completed, :boolean, default: false, null: false
      add :completed_at, :utc_datetime

      timestamps()
    end

    create index(:user_progress, [:user_id])
    create index(:user_progress, [:enum_function_id])
    create unique_index(:user_progress, [:user_id, :enum_function_id])
  end
end
