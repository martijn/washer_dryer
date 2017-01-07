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
  %{ name: 'dryer', gpio_pin: 27, threshold: 23000 },
  %{ name: 'washer', gpio_pin: 22, threshold: 23000 }
]

config :washer_dryer, :heartbeat_led, %{ gpio_pin: 24 }
