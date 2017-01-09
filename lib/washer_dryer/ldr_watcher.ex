defmodule WasherDryer.LdrWatcher do
  @moduledoc """
  Polls an Ldr and sends a message to the parent process when light is detected
  """

  use GenServer

  alias WasherDryer.Notifier
  import :timer, only: [sleep: 1, tc: 1]

  @interval 1000
  @ldrs Application.get_env(:washer_dryer, :ldrs)

  # External API

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # GenServer implementation

  def init(state) do
    # Trigger initial polling for every configured LDR
    Enum.each @ldrs, fn ldr ->
      Process.send_after(self(), {:poll_gpio, ldr}, @interval)
    end

    {:ok, state}
  end

  def handle_info({:poll_gpio, ldr}, state) do
    discharge_cap(ldr[:gpio_pin])
    {time, :ok} = tc(fn -> wait_for_rise(ldr[:gpio_pin]) end)

    if time < ldr[:threshold] do
      Notifier.ldr_light(ldr, time)
    else
      Notifier.ldr_dark(ldr)
    end

    Process.send_after(self(), {:poll_gpio, ldr}, @interval)
    {:noreply, state}
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
