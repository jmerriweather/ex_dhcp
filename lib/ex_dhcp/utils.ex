defmodule ExDhcp.Utils do

  @moduledoc """
  Utilities that make the DHCP module easy to use.  Typespecs for data types
  and binary and string conversions for ip and mac addresses
  """

  @typedoc "erlang-style ip addresses"
  @type ip4 :: :inet.ip4_address
  @typedoc "mac addresses in the same style as the erlang ip address."
  @type mac :: {byte, byte, byte, byte, byte, byte}

  @doc """
  represents an erlang-style ip4 value as a string, without going through
  a list intermediate.
  """
  @spec ip2str(ip4) :: binary
  def ip2str({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"

  @doc """
  converts an erlang-style ip address, (4-tuple of bytes)
  to a binary stored ip address (in the dhcp packet spec) to
  """
  @spec ip2bin(ip4) :: <<_::32>>
  def ip2bin({a, b, c, d}), do: <<a, b, c, d>>

  @doc """
  converts a binary stored ip address (in the dhcp packet spec) to
  an erlang-style ip address. (4-tuple of bytes)
  """
  @spec bin2ip(<<_::32>>) :: ip4
  def bin2ip(<<a, b, c, d>>), do: {a, b, c, d}

  @doc """
  converts a binary stored mac address (in the dhcp packet spec) to
  an erlang-style mac address. (6-tuple of bytes)
  """
  def bin2mac(<<a, b, c, d, e, f>>), do: {a, b, c, d, e, f}

  @doc """
  converts an erlang-style mac address (6-tuple of bytes) to a
  binary stored mac address (in the dhcp packet spec).
  """
  def mac2bin({a, b, c, d, e, f}), do: <<a, b, c, d, e, f>>

  @doc """
  converts a mac address 6-byte tuple to a string.

  ```elixir
  iex> ExDhcp.Utils.mac2str({1, 2, 3, 16, 255, 254})
  "01:02:03:10:FF:FE"
  ```
  """
  def mac2str(mac = {_, _, _, _, _, _}) do
    mac
    |> Tuple.to_list
    |> Enum.map(&padhex/1)
    |> Enum.join(":")
  end

  @doc """
  converts a mac address string into a raw binary value

  ```elixir
  iex> ExDhcp.Utils.str2mac("01:02:03:10:FF:FE")
  {1, 2, 3, 16, 255, 254}
  ```
  """
  def str2mac(<<a::16, ":", b::16, ":", c::16, ":", d::16, ":", e::16, ":", f::16>>) do
    [<<a::16>>, <<b::16>>, <<c::16>>, <<d::16>>, <<e::16>>, <<f::16>>]
    |> Enum.map(&String.to_integer(&1, 16))
    |> List.to_tuple
  end

  defp padhex(v) when v < 16, do: "0" <> Integer.to_string(v, 16)
  defp padhex(v), do: Integer.to_string(v, 16)

  @spec cidr2mask(cidr :: 0..32) :: ip4
  @doc """
  creates a subnet mask from a cidr value

  ```elixir
  iex> ExDhcp.Utils.cidr2mask(24)
  {255, 255, 255, 0}
  ```
  """
  def cidr2mask(n) do
    import Bitwise
    <<a, b, c, d>> = <<-1 <<< (32 - n)::32>>
    {a, b, c, d}
  end

end
