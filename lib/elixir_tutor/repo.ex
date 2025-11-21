defmodule ElixirTutor.Repo do
  use Ecto.Repo,
    otp_app: :elixir_tutor,
    adapter: Ecto.Adapters.Postgres
end
