defmodule ElixirTutorWeb.Plugs.EnsureSessionId do
  @moduledoc """
  Ensures that a session_id exists in the session.
  If one doesn't exist, generates and stores a new one.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :session_id) do
      nil ->
        session_id = generate_session_id()
        put_session(conn, :session_id, session_id)

      _session_id ->
        conn
    end
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(32) |> Base.encode64()
  end
end
