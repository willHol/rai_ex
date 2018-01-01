defmodule RaiEx.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      RaiEx.CircuitBreaker,
      :hackney_pool.child_spec(:rai_dicee, [timeout: :infinity, max_connections: 3])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end