defmodule DhcpTest.Behaviour.HandleInformTest do

  @moduledoc false

  use ExUnit.Case, async: true
  alias ExDhcp.Packet

  @moduletag [handle_inform: true, behaviour: true]

  @dhcp_inform %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    options: %{message_type: :inform, parameter_request_list: [1, 3, 15, 6]}
  }

  defmodule InfSrvNoRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.with_port(6732)

    def handle_inform(pack, xid, chaddr, test_pid) do
      send(test_pid, {:inform, xid, pack, chaddr})
      {:norespond, :new_state}
    end
  end

  test "a dhcp inform message gets sent to handle_inform" do
    InfSrvNoRespond.start_link()
    {:ok, sock} = :gen_udp.open(0, [:binary])
    rel_pack = Packet.encode(@dhcp_inform)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6732, rel_pack)
    assert_receive {:inform, xid, pack, chaddr}
    assert pack == @dhcp_inform
    assert xid == @dhcp_inform.xid
    assert chaddr == @dhcp_inform.chaddr
  end

  defmodule InfSrvRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.with_port(6733)

    def handle_inform(pack, _, _, _) do
      # for simplicity, just send back the same packet.
      {:respond, pack, :new_state}
    end
  end

  @localhost {127, 0, 0, 1}

  test "a dhcp inform message can respond to the caller" do
    InfSrvRespond.start_link(self(), client_port: 6734, broadcast_addr: @localhost)
    {:ok, sock} = :gen_udp.open(6734, [:binary, active: true])

    inf_pack = Packet.encode(@dhcp_inform)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6733, inf_pack)

    assert_receive {:udp, _, _, _, binary}
    assert @dhcp_inform == Packet.decode(binary)
  end

  defmodule InfParserlessSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.with_port(6735, dhcp_options: [])

    def handle_inform(pack, xid, chaddr, test_pid) do
      send(test_pid, {:inform, pack, xid, chaddr})
      {:norespond, :new_state}
    end
  end

  test "dhcp will respond to inform without options parsers" do
    InfParserlessSrv.start_link(self(), broadcast_addr: @localhost)
    {:ok, sock} = :gen_udp.open(0, [:binary])
    disc_pack = Packet.encode(@dhcp_inform)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6735, disc_pack)
    assert_receive {:inform, pack, xid, chaddr}
    # make sure that the inner contents are truly unencoded.
    assert %{53 => <<8>>, 55 => <<1, 3, 15, 6>>} == pack.options
    assert xid == @dhcp_inform.xid
    assert chaddr == @dhcp_inform.chaddr
  end

  defmodule InfNoSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.with_port(6736)
  end

  test "not implementing inform is just a-ok" do
    {:ok, srv} = InfNoSrv.start_link(self(), port: 6736)
    {:ok, sock} = :gen_udp.open(0, [:binary])
    disc_pack = Packet.encode(@dhcp_inform)
    :gen_udp.send(sock, {127, 0, 0, 1}, 6736, disc_pack)
    # make sure that the inner contents are truly unencoded.
    Process.sleep(100)
    Process.alive?(srv)
  end

end
