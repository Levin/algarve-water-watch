defmodule Algground.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AlggroundWeb.Telemetry,
      Algground.Repo,
      {DNSCluster, query: Application.get_env(:algground, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Algground.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Algground.Finch},
      # Start a worker by calling: Algground.Worker.start_link(arg)
      # {Algground.Worker, arg},
      # Start to serve requests, typically the last entry
      AlggroundWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Algground.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlggroundWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
