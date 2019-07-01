defmodule DhcpTest.Behaviour.HandlePacketTest do

  @moduledoc false

  use ExUnit.Case, async: true
  alias ExDhcp.Packet

  @moduletag [handle_packet: true, behaviour: true]

  defmodule PckSrvNoRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.with_port(6501)

    def handle_packet(pack, xid, chaddr, test_pid) do
      send(test_pid, {:packet, pack, xid, chaddr})
      {:norespond, :new_state}
    end
  end

  defmodule NoPckSrvNoRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.with_port(6503)
  end

  # offer packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Offer

  @dhcp_offer %Packet{
    op: 2, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    yiaddr: {192, 168, 1, 100},
    siaddr: {192, 168, 1, 1},
    options: %{message_type: :offer, subnet_mask: {255, 255, 255, 0},
      routers: [{192, 168, 1, 1}], lease_time: 86_400, server: {192, 168, 1, 1},
      domain_name_servers: [{9, 7, 10, 15}, {9, 7, 10, 16}, {9, 7, 10, 18}]}
  }

  describe "dhcp offer requests" do
    test "are handled when handle_packet is implemented" do
      PckSrvNoRespond.start_link()
      {:ok, sock} = :gen_udp.open(0, [:binary])
      offer_pack = Packet.encode(@dhcp_offer)
      :gen_udp.send(sock, {127, 0, 0, 1}, 6501, offer_pack)

      assert_receive {:packet, pack, xid, chaddr}
      assert pack == @dhcp_offer
      assert xid == @dhcp_offer.xid
      assert chaddr == @dhcp_offer.chaddr
    end

    test "and no one dies when handle_packet is not implemented" do
      {:ok, pid} = NoPckSrvNoRespond.start_link()
      {:ok, sock} = :gen_udp.open(0, [:binary])
      offer_pack = Packet.encode(@dhcp_offer)
      :gen_udp.send(sock, {127, 0, 0, 1}, 6503, offer_pack)

      Process.sleep(100)
      assert Process.alive?(pid)
    end
  end

  # ack packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Acknowledgement

  @dhcp_ack %Packet{
    op: 2, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    yiaddr: {192, 168, 1, 100},
    siaddr: {192, 168, 1, 1},
    options: %{message_type: :ack, subnet_mask: {255, 255, 255, 0},
      routers: [{192, 168, 1, 1}], lease_time: 86_400, server: {192, 168, 1, 1},
      domain_name_servers: [{9, 7, 10, 15}, {9, 7, 10, 16}, {9, 7, 10, 18}]}
  }

  describe "dhcp ack requests" do
    test "are handled when handle_packet is implemented" do
      PckSrvNoRespond.start_link()
      {:ok, sock} = :gen_udp.open(0, [:binary])
      offer_pack = Packet.encode(@dhcp_ack)
      :gen_udp.send(sock, {127, 0, 0, 1}, 6501, offer_pack)

      assert_receive {:packet, pack, xid, chaddr}
      assert pack == @dhcp_ack
      assert xid == @dhcp_ack.xid
      assert chaddr == @dhcp_ack.chaddr
    end

    test "and no one dies when handle_packet is not implemented" do
      {:ok, pid} = NoPckSrvNoRespond.start_link()
      {:ok, sock} = :gen_udp.open(0, [:binary])
      offer_pack = Packet.encode(@dhcp_ack)
      :gen_udp.send(sock, {127, 0, 0, 1}, 6503, offer_pack)

      Process.sleep(100)
      assert Process.alive?(pid)
    end
  end

  # nak packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Acknowledgement

  @dhcp_nak %Packet{
    op: 2, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    siaddr: {192, 168, 1, 1},
    options: %{message_type: :nak}
  }

  describe "dhcp nak requests" do
    test "are handled when handle_packet is implemented" do
      PckSrvNoRespond.start_link()
      {:ok, sock} = :gen_udp.open(0, [:binary])
      offer_pack = Packet.encode(@dhcp_nak)
      :gen_udp.send(sock, {127, 0, 0, 1}, 6501, offer_pack)

      assert_receive {:packet, pack, xid, chaddr}
      assert pack == @dhcp_nak
      assert xid == @dhcp_nak.xid
      assert chaddr == @dhcp_nak.chaddr
    end

    test "and no one dies when handle_packet is not implemented" do
      {:ok, pid} = NoPckSrvNoRespond.start_link()
      {:ok, sock} = :gen_udp.open(0, [:binary])
      offer_pack = Packet.encode(@dhcp_nak)
      :gen_udp.send(sock, {127, 0, 0, 1}, 6503, offer_pack)

      Process.sleep(100)
      assert Process.alive?(pid)
    end
  end

end
