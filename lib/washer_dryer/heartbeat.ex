defmodule WasherDryer.Heartbeat do
  @moduledoc """
  Blink a heartbeat LED to show we're running
  """

  use GenServer

  import Bitwise, only: [^^^: 2]

  @interval 2000
  @gpio_pin Application.get_env(:washer_dryer, :heartbeat_led)[:gpio_pin]

  # External API

  def start_link(gpio_pin \\ @gpio_pin) do
    GenServer.start_link(__MODULE__, gpio_pin)
  end

  # GenServer implementation

  def init(gpio_pin) do
    {:ok, gpio} = Gpio.start_link(gpio_pin, :output)
    Process.send_after(self(), {:toggle, 1}, @interval)
    {:ok, gpio}
  end

  def handle_info({:toggle, value}, gpio) do
    Gpio.write(gpio, value)
    Process.send_after(self(), {:toggle, value ^^^ 1}, @interval)

    {:noreply, gpio}
  end
end
