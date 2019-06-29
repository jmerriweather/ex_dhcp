defmodule ExDhcp.Application do

  use Application

  def start(_type, _args) do

    children = []

    opts = [strategy: :one_for_one, name: ExDhcp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
