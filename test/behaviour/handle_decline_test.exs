defmodule DhcpTest.Behaviour.HandleDeclineTest do

  @moduledoc false

  use ExUnit.Case, async: true
  alias ExDhcp.Packet

  @moduletag [handle_decline: true, behaviour: true]

  @dhcp_decline %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    options: %{message_type: :decline, parameter_request_list: [1, 3, 15, 6]}
  }

  defmodule DeclSrvNoRespond do
    use ExDhcp

    def init(test_pid), do: {:ok, test_pid}
    def handle_discover(_, _, _, _), do: :error
    def handle_decline(pack, xid, chaddr, test_pid) do
      send(test_pid, {:decline, xid, pack, chaddr})
      {:norespond, :new_state}
    end
    def handle_request(_, _, _, _), do: :error
  end

  test "a dhcp decline message gets sent to handle_decline" do
    DeclSrvNoRespond.start_link(self(), port: 6710)
    {:ok, sock} = :gen_udp.open(0, [:binary])
    disc_pack = Packet.encode(@dhcp_decline)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6710, disc_pack)
    assert_receive {:decline, xid, pack, chaddr}
    assert pack == @dhcp_decline
    assert xid == @dhcp_decline.xid
    assert chaddr == @dhcp_decline.chaddr
  end

  defmodule DeclSrvRespond do
    use ExDhcp

    def init(test_pid), do: {:ok, test_pid}
    def handle_discover(_, _, _, _), do: :error
    def handle_decline(pack, _, _, _) do
      # just reflect the packet, for simplicity.
      {:respond, pack, :new_state}
    end
    def handle_request(_, _, _, _), do: :error
  end

  @localhost {127, 0, 0, 1}
  test "a dhcp decline message can respond to the caller" do
    DeclSrvRespond.start_link(self(), port: 6711, client_port: 6712, broadcast_addr: @localhost)
    {:ok, sock} = :gen_udp.open(6712, [:binary, active: true])

    disc_pack = Packet.encode(@dhcp_decline)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6711, disc_pack)

    assert_receive({:udp, _, _, _, binary})
  end

  defmodule DeclParserlessSrv do
    use ExDhcp, dhcp_options: []

    def init(test_pid), do: {:ok, test_pid}
    def handle_discover(_, _, _, _), do: :error
    def handle_decline(pack, xid, chaddr, test_pid) do
      send(test_pid, {:decline, xid, pack, chaddr})
      {:respond, pack, :new_state}
    end
    def handle_request(_, _, _, _), do: :error
  end

  test "dhcp will respond to decline without options parsers" do
    DeclParserlessSrv.start_link(self(), port: 6713, client_port: 6714, broadcast_addr: @localhost)
    {:ok, sock} = :gen_udp.open(6714, [:binary, active: true])
    disc_pack = Packet.encode(@dhcp_decline)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6713, disc_pack)
    assert_receive {:decline, xid, pack, chaddr}
    # make sure that the inner contents are truly unencoded.
    assert %{55 => <<1, 3, 15, 6>>, 53 => <<4>>}
      == pack.options

    assert chaddr == @dhcp_decline.chaddr
    assert xid == @dhcp_decline.xid

    assert_receive {:udp, _, _, _, packet}

    assert @dhcp_decline == Packet.decode(packet)
  end

end
