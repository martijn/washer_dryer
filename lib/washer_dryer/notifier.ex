defmodule WasherDryer.Notifier do
  @moduledoc """
  The Notifier accepts messages from LdrWatcher servers and sends out
  notifications
  """

  use GenServer

  require Logger

  @pushover_config Application.get_env(:washer_dryer, :pushover)

  # External API

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def ldr_light(ldr, time \\ nil) do
    GenServer.cast(__MODULE__, {:ldr_light, ldr, time})
  end

  def ldr_dark(ldr) do
    GenServer.cast(__MODULE__, {:ldr_dark, ldr})
  end

  # GenServer implementation

  def handle_cast({:ldr_light, ldr, time}, counters) do
    Logger.debug("#{ldr[:name]} is lit (#{counters[ldr[:name]]}x). Rise: #{time}us")

    # Trigger notification after receiving three notifications in a row
    if counters[ldr[:name]] == 2, do: send_notification(ldr)

    {:noreply, Map.update(counters, ldr[:name], 1, &(&1+1))}
  end

  def handle_cast({:ldr_dark, ldr}, counters) do
    Logger.debug("#{ldr[:name]} is dark")

    {:noreply, Map.put(counters, ldr[:name], 0)}
  end

  defp send_notification(ldr) do
    Logger.info("Sending notification for #{ldr[:name]}")

    HTTPotion.post "https://api.pushover.net/1/messages.json", [
      body: "token=#{@pushover_config[:token]}&user=#{@pushover_config[:user]}&title=" <> URI.encode_www_form("#{ldr[:name]} is finished!") <> "&message=" <> URI.encode_www_form(":)"),
      headers: ["Content-Type": "application/x-www-form-urlencoded"]
    ]
  end


end
