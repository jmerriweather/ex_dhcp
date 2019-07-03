defmodule ExDhcpTest.RegressionTest do
  use ExUnit.Case

  alias ExDhcp.Packet

  ## regression test discovered 2 Jul 2019.
  ## Intel-NUC PXE booter emitted the following DHCP packet:

  @nuc_packet %Packet{
    chaddr: {244, 77, 48, 108, 147, 178},
    ciaddr: {0, 0, 0, 0},
    flags: 32_768,
    giaddr: {0, 0, 0, 0},
    hlen: 6,
    hops: 0,
    htype: 1,
    op: 1,
    options: %{
      client_ndi: {1, 3, 16},
      client_system: <<0, 7>>,
      max_message_size: 1472,
      message_type: :discover,
      parameter_request_list: [1, 2, 3, 4, 5, 6, 12, 13, 15, 17, 18, 22, 23, 28,
       40, 41, 42, 43, 50, 51, 54, 58, 59, 60, 66, 67, 97, 128, 129, 130, 131,
       132, 133, 134, 135],
      uuid_guid: <<0, 238, 195, 92, 194, 252, 183, 253, 21, 170, 124, 244, 77, 48,
        108, 147, 178>>,
      vendor_class_identifier: "PXEClient:Arch:00007:UNDI:003016"
    },
    secs: 28,
    siaddr: {0, 0, 0, 0},
    xid: 205_646_044,
    yiaddr: {0, 0, 0, 0}
  }

  #
  # this caused the DHCP system to crash because it wasn't expecting that the UUID/GUID
  # parameter could have an extra zero in front of it.
  #
  # mitigation:  just have uuid/guid parse as a naked string and let the operator decide
  # how to handle parsing UUID/GUID
  #

  test "nuc DHCP packet is handled correctly" do
    assert @nuc_packet == @nuc_packet
    |> Packet.encode
    |> :erlang.iolist_to_binary
    |> Packet.decode
  end

end
