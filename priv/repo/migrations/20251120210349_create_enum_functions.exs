defmodule ElixirTutor.Repo.Migrations.CreateEnumFunctions do
  use Ecto.Migration

  def change do
    create table(:enum_functions) do
      add :name, :string, null: false
      add :arity, :integer, null: false
      add :documentation, :text
      add :examples, :text

      timestamps()
    end

    create unique_index(:enum_functions, [:name, :arity])
  end
end
