defmodule ElixirTutorWeb.PageController do
  use ElixirTutorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
