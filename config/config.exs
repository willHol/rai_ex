# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :rai_ex,
  url: "http://localhost",
  port: 7076,
  min_receive: 1_000_000_000_000_000_000_000_000,
  breaker_max_error: 3,
  breaker_period: 1000
