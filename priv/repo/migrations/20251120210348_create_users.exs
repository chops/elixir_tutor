defmodule ElixirTutor.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :session_id, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:session_id])
  end
end
