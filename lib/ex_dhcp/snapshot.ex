if Mix.env == :test do

defmodule ExDhcp.Snapshot.Client do

  alias ExDhcp.Packet
  alias ExDhcp.Utils

  @moduledoc """
  this module provides tools for developing snapshots for testing purposes.
  """

  @doc """
  sends a broadcast DHCP request and saves the resulting structure to `filepath`.
  you should supply the mac address string in `mac_str`.
  """
  def send_discover(mac_str, filepath, opts) do

    port = opts[:port] || 68

    {:ok, sock} = :gen_udp.open(port, [:binary, active: true, broadcast: true, ifaddr: {0, 0, 0, 0}])

    mac_addr = Utils.str2mac(mac_str)

    options = opts
    |> Keyword.drop([:port])
    |> Enum.into(%{message_type: :discover, parameter_request_list: [1, 13, 15, 6]})

    dsc = %Packet{op: 1, htype: 1, hlen: 6, hops: 0, chaddr: mac_addr, options: options}

    :gen_udp.send(sock, {255, 255, 255, 255}, 67, Packet.encode(dsc))

    receive do
      {:udp, _, _, _, resp} ->

        response_txt = resp
        |> Packet.decode
        |> inspect

        File.write!(filepath, response_txt)

    after 60000 ->
      raise "discover message not received"
    end

  end
end #client

defmodule ExDhcp.Snapshot.Server do

  @moduledoc """
  implements a snapshot server.  This will log all DHCP messages that are sent to
  this sever to a directory.  File format will be as follows.  Content will be an
  inspected `%Packet{}` datatype.
  `dhcp-<message-type>-<timestamp>.txt`
  """
  use ExDhcp

  @type state :: %{path: Path.t}

  @impl true
  @spec init(any) :: {:ok, any}
  def init(state), do: {:ok, state}

  @spec output(Packet.t, state) :: {:norespond, state}
  defp output(p, state) do
    content = inspect p
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601(:basic)
    filename = "dhcp-#{p.options.message_type}-#{timestamp}.txt"

    state.path
    |> Path.join(filename)
    |> File.write!(content)

    {:norespond, state}
  end

  @impl true
  @spec handle_discover(Packet.t, any, any, state) :: {:norespond, state}
  def handle_discover(p, _, _, state), do: output(p, state)

  @impl true
  @spec handle_request(Packet.t, any, any, state) :: {:norespond, state}
  def handle_request(p, _, _, state), do: output(p, state)

  @impl true
  @spec handle_decline(Packet.t, any, any, state) :: {:norespond, state}
  def handle_decline(p, _, _, state), do: output(p, state)

  @impl true
  @spec handle_inform(Packet.t, any, any, state) :: {:norespond, state}
  def handle_inform(p, _, _, state), do: output(p, state)

  @impl true
  @spec handle_release(Packet.t, any, any, state) :: {:norespond, state}
  def handle_release(p, _, _, state), do: output(p, state)

  @impl true
  @spec handle_packet(Packet.t, any, any, state) :: {:norespond, state}
  def handle_packet(p, _, _, state), do: output(p, state)

end  # Server

end  # Mix.env == :test fence
