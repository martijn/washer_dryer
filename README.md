# WasherDryer

This project aims to notify me when my washer or dryer finished it's cycle. The
hardware contraption that goes with it is illustrated in this tweet:

    https://twitter.com/martijnstorck/status/561631901392592897

Basically it's two circuits of 200K LDR's and 1uF capacitors. We discharge the
capacitor by pulling the GPIO pin low, then wait for it to charge again. The
faster the GPIO pin rises, the more light is sensed by the LDR.

This is a rewrite of my original hacked together Python script and is a work
in progress.

To compile the app (default target is rpi):

  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`
