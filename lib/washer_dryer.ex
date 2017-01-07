defmodule WasherDryer do
  use Application
  require Logger
  import :timer, only: [ sleep: 1, tc: 3]

  @ldrs Application.get_env(:washer_dryer, :ldrs)
  @heartbeat_led Application.get_env(:washer_dryer, :heartbeat_led)

  def start(_type, _args) do
    # Start heartbeat led
    {:ok, heartbeat_gpio} = Gpio.start_link(@heartbeat_led[:gpio_pin], :output)
    spawn(WasherDryer, :blink_heartbeat_led, [heartbeat_gpio])

    # Spawn main_loop in seperate process so we can drop to an IEx console
    # We start this first so LDR watchers can send their message to this process
    main = spawn(WasherDryer, :main_loop, [])

    # Start LDR watchers
    Enum.each @ldrs, fn ldr ->
      spawn(WasherDryer, :watch_ldr, [main, ldr])
    end

    {:ok, self()}
  end

  def main_loop do
    receive do
      {:ldr, :dark, name, time} -> true
      {:ldr, :light, name, time} ->
        Logger.info "#{name} is ready!"
        Logger.debug "#{name} time to rise/timeout was #{time}us"
    end

    main_loop()
  end

  def watch_ldr(parent, %{name: name, gpio_pin: gpio_pin, threshold: threshold}) do
    discharge_cap(gpio_pin)

    {time, :ok} = tc(WasherDryer, :wait_for_rise, [gpio_pin])

    cond do
      time >= threshold ->
        send parent, {:ldr, :dark, name, time}
      true ->
        send parent, {:ldr, :light, name, time}
    end

    sleep 1000

    watch_ldr(parent, %{name: name, gpio_pin: gpio_pin, threshold: threshold})
  end

  def discharge_cap(gpio_pin) do
    {:ok, gpio_out} = Gpio.start_link(gpio_pin, :output)
    Gpio.write(gpio_out, 0)
    sleep 100
    Gpio.release(gpio_out)
  end

  def wait_for_rise(gpio_pin) do
    {:ok, gpio_in} = Gpio.start_link(gpio_pin, :input)

    Gpio.set_int(gpio_in, :rising)

    receive do
      {:gpio_interrupt, _p, :rising} ->
        true # already risen (really light)
      {:gpio_interrupt, p, :falling} ->
        receive do
          {:gpio_interrupt, p, :rising} ->
            true # rise event detected
          after 100 ->
            true # anything above 100ms is really dark
          end
    end

    Gpio.set_int(gpio_in, :none)

    Gpio.release(gpio_in)
  end

  def blink_heartbeat_led(gpio) do
    Gpio.write(gpio, 1); sleep(2000)
    Gpio.write(gpio, 0); sleep(2000)
    blink_heartbeat_led(gpio)
  end
end
