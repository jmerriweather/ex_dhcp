defmodule ExDhcp.Packet do

  @moduledoc """
  provides a structure for the DHCP UDP packet, according to the spec.

  [https://tools.ietf.org/html/rfc1531]()

  For a simpler reference on the DHCP protocol's binary layout, refer to the
  wikipedia page:

  [https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol]()

  - op:  operation (request: 1, response: 2).  ExDhcp will *only* respond to
    requests (except in handle_packet) and *only* send response packets.
  - htype: specifies the hardware address type.  Currently ony ethernet is supported.
  - hlen:  specifies the hardware address length.  Currently only 6-byte MAC is supported.
  - hops:  number of hops, for when you do relay-DHCP
  - xid:   transaction id.  Allows multiple DHCP requests to be serviced concurrently.  In
  this library, separate servers will be spawned to handle different transmissions.
  - secs:   seconds since client has booted
  - flags:  DHCP flags (see RFC 1531, figure 2)
  - ciaddr: "client internet address" (expected in `:request` requests)
  - yiaddr: "'your' (client) internet address" (expected in `:offer` responses)
  - siaddr: "next server internet address" (expected in some `:offer`, `:ack`, and `:nak` responses)
  - giaddr: "gateway internet address (for use when doing relay-dhcp)
  - options: {integer, tuple} list.  Supported opcodes will be translated
  into {atom, value} pairs by Options parser modules (see `ExDhcp.Options.Macro`)
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

  @typedoc """
  the Packet struct type.

  See `ExDhcp.Packet` for details on the struct parameters.
  """
  @type t::%__MODULE__{
    op:      1 | 2,
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
  converts a udp packet or a binary payload from a udp packet and converts
  it to a `ExDhcp.Packet` struct.

  NB: This function will fail if you attempt to pass it a udp packet that does
  not contain the DHCP "magic cookie".
  """
  @spec decode(udp_packet | binary, [module]) :: t
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
  Converts from a `ExDhcp.Packet` struct into an `iolist`.

  Typically, this will be sent directly to a `:gen_udp.send/2` call.  If
  you need to examine the contents of the iolist as a binary, you may want
  to send the results to `:erlang.iolist_to_binary/1`
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

  @spec respond(t, :offer | :ack | :nak, keyword) :: t
  @doc """
  A convenience function to craft a DHCP response based on the request.

  `type` should be one of `[:offer, :ack, :nak]` (though in principle
  you could set it to any of the DHCP message types)

  The builtin values are reflected without change.  The DHCP opcode is
  automatically set to 2.  The options list is stripped.

  You should pass any response and options parameters as a *flat* keyword
  list; all of the keys should be encodable by at least one of your options
  parsing modules.  If you need to encode a value directly as an integer/binary
  pair, do not use `respond/3`.
  """
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
