# WasherDryer

This project aims to notify me when my washer or dryer finished it's cycle. The
hardware contraption that goes with it is looks as follows:

![Accompanying hardware](https://www.martijnstorck.nl/stuff/washer-dryer.jpg)

Basically it's two circuits of 200K LDRs and 1uF capacitors. We discharge the
capacitor by pulling the GPIO pin low, then wait for it to charge again. The
faster the GPIO pin rises, the more light is sensed by the LDR.

This project is built with [Nerves](http://nerves-project.org), a
platform/framework/toolchain that leverages [Elixir](http://elixir-lang.org)
for embedded applications. It targets the Raspberry Pi Zero and notifications
are sent using [Pushover](https://pushover.net).

To compile the application:

  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`
