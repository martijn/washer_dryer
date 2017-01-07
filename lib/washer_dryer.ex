defmodule WasherDryer do
  @moduledoc """
  Main module for WasherDryer.
  """

  use Application

  import :timer, only: [sleep: 1, tc: 3]
  require Logger

  # Main entry point for the application
  def start(_type, _args) do
    # Start heartbeat led
    heartbeat_led = Application.get_env(:washer_dryer, :heartbeat_led)
    {:ok, heartbeat_gpio} = Gpio.start_link(heartbeat_led[:gpio_pin], :output)
    spawn(WasherDryer, :blink_heartbeat_led, [heartbeat_gpio])

    # Spawn main_loop in seperate process so we can drop to an IEx console
    # We start this first so LDR watchers can send their message to this process
    main = spawn_link(WasherDryer, :main_loop, [])

    # Start LDR watchers
    Enum.each Application.get_env(:washer_dryer, :ldrs), fn ldr ->
      spawn(WasherDryer, :watch_ldr, [main, ldr])
    end

    {:ok, self()}
  end

  # Main loop that processes messages from the various workers
  def main_loop do
    receive do
      {:ldr_light, ldr, time} ->
        Logger.info("#{ldr[:name]} is ready!")
        Logger.debug("#{ldr[:name]} time to rise/timeout was #{time}us")
    end

    main_loop()
  end

  # Monitor an LDR on a GPIO pin and notify parent if light is detected
  def watch_ldr(parent, ldr) do
    discharge_cap(ldr[:gpio_pin])

    {time, :ok} = tc(WasherDryer, :wait_for_rise, [ldr[:gpio_pin]])

    if time < ldr[:threshold], do: send(parent, {:ldr_light, ldr, time})

    sleep(1000)

    watch_ldr(parent, ldr)
  end

  # Pull down a GPIO pin for 100ms to discharge the attached capacitor
  def discharge_cap(gpio_pin) do
    {:ok, gpio} = Gpio.start_link(gpio_pin, :output)
    Gpio.write(gpio, 0)
    sleep(100)
    Gpio.release(gpio)
  end

  # Wait for a GPIO pin to rise (or return immediately if it has already risen)
  def wait_for_rise(gpio_pin) do
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

  def blink_heartbeat_led(gpio) do
    Gpio.write(gpio, 1); sleep(2000)
    Gpio.write(gpio, 0); sleep(2000)
    blink_heartbeat_led(gpio)
  end
end
