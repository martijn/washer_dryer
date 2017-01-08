defmodule WasherDryer do
  @moduledoc """
  Main module for WasherDryer.
  """

  use Application

  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(WasherDryer.Main, []),
      worker(WasherDryer.Heartbeat, [])
    ] ++ Enum.map Application.get_env(:washer_dryer, :ldrs), fn ldr ->
      worker(WasherDryer.LdrWatcher, [ldr], id: "LdrWatcher-#{ldr[:name]}")
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WasherDryer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
