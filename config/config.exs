# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.Project.config[:target]}.exs"

config :washer_dryer, :ldrs, [
  %{
    name: 'Dryer',
    gpio_pin: 27,
    threshold: 23000,
    message_title: "The dryer is finished!",
    message_body: "Go turn it off to save power"
  },
  %{
    name: 'Washer',
    gpio_pin: 22,
    threshold: 23000,
    message_title: "The washer is finished!",
    message_body: "Get that laundry out before it starts to smell ;)"
  }
]

config :washer_dryer, :heartbeat_led, %{ gpio_pin: 24 }

config :washer_dryer, :pushover, %{
  token: "<your pushover token>",
  user: "<your pushover user>"
}

import_config "#{Mix.env}.exs"
