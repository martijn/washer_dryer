# WasherDryer

This [Nerves](http://nerves-project.org) project aims to notify me when my
washer or dryer finished it's cycle. The hardware contraption that goes with it
is looks as follows:

![Accompanying hardware](https://www.martijnstorck.nl/stuff/washer-dryer.jpg)

Basically it's two circuits of 200K LDR's and 1uF capacitors. We discharge the
capacitor by pulling the GPIO pin low, then wait for it to charge again. The
faster the GPIO pin rises, the more light is sensed by the LDR.

It sends notifications to my phone using [Pushover](https://pushover.net).

To compile the app (default target is rpi):

  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`
