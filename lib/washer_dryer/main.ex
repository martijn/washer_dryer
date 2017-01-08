defmodule WasherDryer.Main do
  @moduledoc """
  The Main server accepts messages from LdrWatcher servers and sends out
  notifications
  """

  use GenServer

  require Logger

  # External API

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def ldr_lit(ldr, time) do
    GenServer.cast(__MODULE__, {:ldr_lit, ldr, time})
  end

  # GenServer implementation

  def handle_cast({:ldr_lit, ldr, time}, state) do
    Logger.info("#{ldr[:name]} is ready!")
    Logger.debug("#{ldr[:name]} time to rise/timeout was #{time}us")

    {:noreply, state}
  end
end
