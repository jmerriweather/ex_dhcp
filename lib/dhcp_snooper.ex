if Mix.env == :dev do
  defmodule DhcpSnooper do

    @moduledoc """
    A tool for snooping on DHCP transactions that are passing by this particular
    node.  Pinned to the `:dev` environment.

    ## Usage

    ```elixir
    DhcpSnooper.start_link(:ok)
    ```

    This will cause DHCP packets streaming to be logged to the console.
    """

    use ExDhcp

    require Logger

    @impl true
    def init(_), do: {:ok, :ok}

    @impl true
    def handle_discover(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:noreply, :ok}
    end

    @impl true
    def handle_request(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:noreply, :ok}
    end

    @impl true
    def handle_decline(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:noreply, :ok}
    end

    @impl true
    def handle_inform(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:noreply, :ok}
    end

    @impl true
    def handle_release(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:noreply, :ok}
    end

    @impl true
    def handle_packet(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:noreply, :ok}
    end
  end
end
