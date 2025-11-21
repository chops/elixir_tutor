defmodule ElixirTutor.Repo.Migrations.CreateUserNotes do
  use Ecto.Migration

  def change do
    create table(:user_notes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :enum_function_id, references(:enum_functions, on_delete: :delete_all), null: false
      add :content, :text

      timestamps()
    end

    create index(:user_notes, [:user_id])
    create index(:user_notes, [:enum_function_id])
    create unique_index(:user_notes, [:user_id, :enum_function_id])
  end
end
