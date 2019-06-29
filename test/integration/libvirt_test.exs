defmodule ExDhcp.LibvirtTest do
  # directly tests DHCP functionality using libvirt.
  # tests in two modes - the first mode being unbound to an interface,
  # second mode being bound to an interface.

  #use ExUnit.Case
#
  #@moduletag :libvirt
#
  #defmodule TestDhcp do
  #  use ExDhcp
#
  #  @impl true
  #  def init(test_pid), do: {:ok, test_pid}
  #  @impl true
  #  def handle_discover(packet, xid, macaddr, test_pid) do
  #    IO.inspect(packet)
  #  end
  #  @impl true
  #  def handle_decline(_, _, _, _), do: {:noreply, nil}
  #  @impl true
  #  def handle_request(_, _, _, _), do: {:noreply, nil}
  #end
#
  #describe "when used in unbound mode" do
  #  @tag [timeout: :infinity]
  #  test "correctly assigns the IP address of an ubuntu VM" do
  #    {:ok, lst} = :inet.getif()
#
  #    # presumes that the bridge IP is the only bound IP address to which
  #    # the test host is a single value
#
  #    ip = lst
  #    |> Enum.filter(fn
  #      {{127, 0, 0, 1}, _, _} -> false
  #      {{_, _, _, 1}, _, _} -> true
  #      _ -> false
  #    end)
  #    |> case do
  #      [] -> raise "no hosting bridges found!"
  #      [{ip, _, _}] -> ip
  #      _ -> raise "multiple hosting bridges found; cannot disambiguate."
  #    end
#
  #    {:ok, pid} = TestDhcp.start_link(port: 6767)
#
  #    Process.sleep(50)
#
  #    # verify that we can correctly listen to signals on port 67
  #    {:ok, sock} = :gen_udp.open(0, [:binary]) |> IO.inspect(label: "48")
  #    :gen_udp.send(sock, ip, 6767, "test")  |> IO.inspect(label: "49")
  #    :gen_udp.send(sock, {127, 0, 0, 1}, 6767, "test")  |> IO.inspect(label: "49")
  #    :gen_udp.send(sock, {192, 168, 8, 173}, 6767, "test")  |> IO.inspect(label: "49")
  #    Process.sleep(200)
  #    assert_receive :test_ping
#
  #    #:gen_udp.send(sock, ip, 67, "test")
#
#
  #    vmdef = Path.join(File.cwd!(), "assets/default-vm.xml")
#
  #    # System.cmd("virsh", ["create", vmdef])
#
  #    receive do after :infinity -> :ok end
#
  #  end
  #end
#
#
#
end
