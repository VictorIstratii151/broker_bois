defmodule MessageBroker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised

    :ets.new(:topics, [:set, :public, :named_table])

    children = [
      {Task, fn -> MessageBroker.accept(1337) end}
      # Starts a worker by calling: MessageBroker.Worker.start_link(arg)
      # {MessageBroker.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MessageBroker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
