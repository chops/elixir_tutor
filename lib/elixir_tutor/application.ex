defmodule ElixirTutor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirTutorWeb.Telemetry,
      ElixirTutor.Repo,
      {DNSCluster, query: Application.get_env(:elixir_tutor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirTutor.PubSub},
      # Start a worker by calling: ElixirTutor.Worker.start_link(arg)
      # {ElixirTutor.Worker, arg},
      # Start to serve requests, typically the last entry
      ElixirTutorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirTutor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirTutorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
