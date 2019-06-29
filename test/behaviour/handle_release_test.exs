defmodule DhcpTest.Behaviour.HandleReleaseTest do

  @moduledoc false

  use ExUnit.Case, async: true
  alias ExDhcp.Packet

  @moduletag [handle_release: true, behaviour: true]

  @dhcp_release %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    ciaddr: {192, 168, 1, 100},
    siaddr: {192, 168, 1, 1},
    options: %{message_type: :release}
  }

  defmodule RelSrvNoRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.with_port(6742)

    def handle_release(pack, xid, chaddr, test_pid) do
      send(test_pid, {:release, xid, pack, chaddr})
      {:norespond, :new_state}
    end
  end

  test "a dhcp release message gets sent to handle_release" do
    RelSrvNoRespond.start_link(self(), port: 6742)
    {:ok, sock} = :gen_udp.open(0, [:binary])
    rel_pack = Packet.encode(@dhcp_release)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6742, rel_pack)
    assert_receive {:release, xid, pack, chaddr}
    assert pack == @dhcp_release
    assert xid == @dhcp_release.xid
    assert chaddr == @dhcp_release.chaddr
  end

  defmodule RelParserlessSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.with_port(6743, dhcp_options: [])

    def handle_release(pack, xid, chaddr, test_pid) do
      send(test_pid, {:release, pack, xid, chaddr})
      {:norespond, :new_state}
    end
  end

  test "dhcp will respond to release without options parsers" do
    RelParserlessSrv.start_link()
    {:ok, sock} = :gen_udp.open(0, [:binary])
    disc_pack = Packet.encode(@dhcp_release)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6743, disc_pack)
    assert_receive {:release, pack, xid, chaddr}
    # make sure that the inner contents are truly unencoded.
    assert %{53 => <<7>>} == pack.options
    assert xid == @dhcp_release.xid
    assert chaddr == @dhcp_release.chaddr
  end

  defmodule RelNoSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.with_port(6744)
  end

  test "not implementing release is just a-ok" do
    {:ok, srv} = RelNoSrv.start_link()
    {:ok, sock} = :gen_udp.open(0, [:binary])
    disc_pack = Packet.encode(@dhcp_release)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6744, disc_pack)
    # make sure that the inner contents are truly unencoded.
    Process.sleep(100)
    Process.alive?(srv)
  end

end
