defmodule WasherDryer.Mixfile do
  use Mix.Project

  @target System.get_env("NERVES_TARGET") || "rpi"

  def project do
    [app: :washer_dryer,
     version: "0.1.0",
     target: @target,
     archives: [nerves_bootstrap: "~> 0.2.1"],
     deps_path: "deps/#{@target}",
     build_path: "_build/#{@target}",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps() ++ system(@target)]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {WasherDryer, []},
     applications: [:elixir_ale, :httpotion, :logger, :nerves_interim_wifi]]
  end

  def deps do
    [{:nerves, "~> 0.4.0"},
     {:elixir_ale, "~> 0.5.6"},
     {:httpotion, "~> 3.0.2"},
     {:nerves_interim_wifi, "~> 0.1.0"},
     {:credo, "~> 0.5", only: [:dev, :test]}]
  end

  def system(target) do
    [{:"nerves_system_#{target}", ">= 0.0.0"}]
  end

  def aliases do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

end
