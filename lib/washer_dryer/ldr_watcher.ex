defmodule WasherDryer.LdrWatcher do
  @moduledoc """
  Polls an Ldr and sends a message to the parent process when light is detected
  """

  use GenServer

  alias WasherDryer.Main
  import :timer, only: [sleep: 1, tc: 2]

  @interval 1000

  # External API

  def start_link(ldr) do
    GenServer.start_link(__MODULE__, ldr)
  end

  # GenServer implementation

  def init(ldr) do
    Process.send_after(self(), :poll_gpio, @interval)
    {:ok, ldr}
  end

  def handle_info(:poll_gpio, ldr) do
    discharge_cap(ldr[:gpio_pin])
    {time, :ok} = tc(WasherDryer, fn -> wait_for_rise(ldr[:gpio_pin]) end)

    if time < ldr[:threshold], do: Main.ldr_lit(ldr, time)

    Process.send_after(self(), :poll_gpio, @interval)
    {:noreply, ldr}
  end

  # Private methods

  # Pull down a GPIO pin for 100ms to discharge the attached capacitor
  defp discharge_cap(gpio_pin) do
    {:ok, gpio} = Gpio.start_link(gpio_pin, :output)

    Gpio.write(gpio, 0)
    sleep(100)

    Gpio.release(gpio)
  end

  # Wait for a GPIO pin to rise (or return immediately if it has already risen)
  defp wait_for_rise(gpio_pin) do
    {:ok, gpio} = Gpio.start_link(gpio_pin, :input)
    Gpio.set_int(gpio, :rising)

    receive do
      {:gpio_interrupt, _, :rising} ->
        :ok # already risen (really light)
      {:gpio_interrupt, _, :falling} ->
        receive do
          {:gpio_interrupt, _, :rising} ->
            :ok # rise event detected
          after 100 ->
            :timeout # anything above 100ms is really dark
          end
    end

    # Prevent gpio_lock_as_irq errors in Linux 3.13 through 3.18
    Gpio.set_int(gpio, :none)
    Gpio.release(gpio)
  end
end
