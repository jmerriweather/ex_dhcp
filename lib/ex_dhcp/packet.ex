defmodule ExDhcp.Packet do

  @moduledoc """
  provides a structure for the DHCP packet, according to the spec.

  (http://en.wikipedia.org/wiki/DHCP)

  the fields are as follows:

  -  op:  operation (request: 1, response: 2).  This operation value allows DHCP providers
  to coexist with other DHCP providers.  Since DHCP packets are broadcast to 255.255.255.255,
  without this feature, they might be

  - htype: specifies the hardware address type.  Currently ony ethernet is supported.
  - hlen:  specifies the hardware address length.  Currently only 6-byte MAC is supported.
  - hops:
  - xid:   transmission id.  Allows multiple DHCP requests to be serviced concurrently.  In
  this library, separate servers will be spawned to handle different transmissions.
  - secs:
  - flags:
  - ciaddr: "current internet address"
  - yiaddr: "your internet address"
  - siaddr: "server internet address"
  - giaddr: "gateway internet address
  - options: {integer, tuple} list.  Supported opcodes will be translated
  into {atom, value} pairs.
  """

  alias ExDhcp.Options
  alias ExDhcp.Options.Basic
  alias ExDhcp.Utils

  @magic_cookie   <<0x63, 0x82, 0x53, 0x63>>
  @op_response    2
  @htype_ethernet 1
  @hlen_macaddr   6

  defstruct op: @op_response,
            htype: @htype_ethernet,
            hlen: @hlen_macaddr,
            hops: 0,
            xid: 0,
            secs: 0,
            flags: 0,
            ciaddr: {0, 0, 0, 0},
            yiaddr: {0, 0, 0, 0},
            siaddr: {0, 0, 0, 0},
            giaddr: {0, 0, 0, 0},
            chaddr: {0, 0, 0, 0, 0, 0},
            options: []

  @type option :: {non_neg_integer, binary} | {atom, any}

  @type t(v)::%__MODULE__{
    op:      v,
    htype:   1,
    hlen:    6,
    hops:    non_neg_integer,
    xid:     non_neg_integer,
    secs:    non_neg_integer,
    flags:   non_neg_integer,
    ciaddr:  Utils.ip4,
    yiaddr:  Utils.ip4,
    siaddr:  Utils.ip4,
    giaddr:  Utils.ip4,
    chaddr:  Utils.mac,
    options: %{
      optional(non_neg_integer) => binary,
      optional(atom) => any
    }
  }

  @type t::t(1) | t(2)

  @type request ::t(1)
  @type response::t(2)

  @typedoc """
  erlang's internal representation of an active udp packet.
  """
  @type udp_packet :: {
    :udp,
    :gen_udp.socket,
    Utils.ip4,
    :inet.ancillary_data,
    binary}

  @bootp_octets 192 * 8

  @doc """
  pass the contents of a udp packet
  """
  @spec decode(udp_packet | binary, [module]) :: t | udp_packet
  def decode(udp_packet, option_parsers \\ [Basic])
  def decode({:udp, _, _, _, binary = <<_::1888>> <> @magic_cookie <> _}, option_parsers) do
    decode(binary, option_parsers)
  end
  def decode(
        <<op, htype, @hlen_macaddr, hops, xid::size(32), secs::size(16),
          flags::size(16), ciaddr::binary-size(4), yiaddr::binary-size(4),
          siaddr::binary-size(4), giaddr::binary-size(4), chaddr::binary-size(6),
          0::80, 0::@bootp_octets, @magic_cookie>> <> options,
          option_parsers) do

    %__MODULE__{
      op: op,
      htype: htype,
      hops: hops,
      xid: xid,
      secs: secs,
      flags: flags,
      ciaddr: Utils.bin2ip(ciaddr),
      yiaddr: Utils.bin2ip(yiaddr),
      siaddr: Utils.bin2ip(siaddr),
      giaddr: Utils.bin2ip(giaddr),
      chaddr: Utils.bin2mac(chaddr),
      options: Options.decode(options, option_parsers)
    }
  end

  @doc """
  Encode a message so that it can be put in a UDP packet
  """
  @spec encode(t) :: iolist
  def encode(message, modules \\ [Basic]) do
    options = Options.encode(message.options, modules)
    ciaddr = Utils.ip2bin(message.ciaddr)
    yiaddr = Utils.ip2bin(message.yiaddr)
    siaddr = Utils.ip2bin(message.siaddr)
    giaddr = Utils.ip2bin(message.giaddr)
    chaddr = Utils.mac2bin(message.chaddr)

    [message.op, message.htype, message.hlen, message.hops, <<message.xid::32>>,
     <<message.secs::16>>, <<message.flags::16>>, ciaddr, yiaddr, siaddr, giaddr,
     chaddr, <<0::80>>, <<0::@bootp_octets>>, @magic_cookie | options]
  end

  @builtin_options [:op, :htype, :hlen, :hops, :xid, :secs, :flags,
    :ciaddr, :yiaddr, :siaddr, :giaddr, :chaddr]

  @message_type 53
  @message_map %{discover: <<1>>,
                 offer:    <<2>>,
                 request:  <<3>>,
                 decline:  <<4>>,
                 ack:      <<5>>,
                 nak:      <<6>>,
                 release:  <<7>>,
                 inform:   <<8>>}

  def respond(packet = %__MODULE__{}, type, opts) do
    builtins = opts
    |> Keyword.take(@builtin_options)
    |> Enum.into(%{op: 2})

    extras = opts
    |> Keyword.drop(@builtin_options)
    |> Enum.into(%{@message_type => @message_map[type]})

    packet
    |> Map.merge(builtins)
    |> Map.put(:options, extras)
  end
end
