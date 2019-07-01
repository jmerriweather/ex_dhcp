# ExDhcp

**An instrumentable dhcp GenServer for Elixir**

<img src="https://api.travis-ci.com/RstorLabs/ex_dhcp.svg?branch=master"/>

## General Description:

Largely inspired by:  [https://github.com/fhunleth/one_dhcpd]()
We couldn't use GPL licenced material in-house, so this project was
derived from `one_dhcpcd`.  It's an instrumentable DHCP GenServer,
with an opinionated interface that takes after the `GenStage` design.
At the moment, unlike one_dhcpd, it does not implement a full DHCP
server, but you *could* use ExDhcp to implement that functionality.

If you need DHCP functionality for some other purpose (such as PXE
booting) ExDhcp is ideal.  If you would like to easily implement 
distributed DHCP with custom code hooks for custom functionality, ExDhcp 
might be for you.

## Usage Notes:

A minimal DhcpServer implements `handle_discover`, `handle_request`, and
`handle_decline`, and might look something like this:

```elixir

defmodule MyDhcpServer do
  use ExDhcp
  alias ExDhcp.Packet

  def start_link(init_state) do
    ExDhcp.start_link(__MODULE__, init_state)
  end

  @impl true
  def init(init_state), do: {:ok, init_state}

  @impl true
  def handle_discover(request, xid, mac, state) do
    # code.  Should assign the unimplemented values 
    # for the response below:
    response = Packet.respond(request, :offer,
      yiaddr: issued_your_address,
      siaddr: server_ip_address,
      subnet_mask: subnet_mask,
      routers: [router],
      lease_time: lease_time,
      server: server_ip_address,
      domain_name_servers: [dns_server]))
    {:respond, response, new_state}
  end

  @impl true
  def handle_request(request, xid, mac, state) do
    # code
    response = Packet.respond(request, :ack,
      yiaddr: issued_your_address ...)
    {:respond, response, state}
  end

  @impl true
  def handle_decline(request, xid, mac, state) do
    # code
    response = Packet.respond(request, :offer,
      yiaddr: new_issued_address ...)
    {:respond, response, state}
  end

end

```
For more details, see the documentation.

### Deployment

The DHCP protocol [https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol]() 
listens in on port *67*, which is below the privileged port limit 
*(1024)* for most, e.g. Linux distributions.  ExDhcp doesn't presume
that it will be running as root or have access to that port, and by
default listens in to port *6767*.  If you expect to have access to 
privileged ports, you can set the port number in the module configuration.

Alternatively, on most linux distributions you can use `iptables` to 
forward broadcast UDP from port *67* to port *6767* and vice versa.  
The following incantations will achieve this (if you're using a port besides
6767, be sure to replace it wih your chosen port):

```bash
iptables -t nat -I PREROUTING -p udp --src 0.0.0.0 --dport 67 -j DNAT --to 0.0.0.0:6767
iptables -t nat -A POSTROUTING -p udp --sport 6767 -j SNAT --to <server ip address>:67
```

There may be situations where you would like to bind DHCP activity to 
a specific ethernet interface.  This is settable from the module settings,
but in order to successfully bind to to the interface, on Linux machines,
you'll have to do the following (as superuser):

```bash
setcap cap_net_raw=ep /path/to/beam.smp
```

## TODOs

- publish to hex.pm

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_dhcp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_dhcp, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dhcp](https://hexdocs.pm/dhcp).

