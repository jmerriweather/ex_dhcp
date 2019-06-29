defmodule ExDhcp.Options do

  alias ExDhcp.Utils

  @moduledoc false

  @option_padding 0
  @option_finish 255

  @type typecode::byte

  @type decoded_options :: %{optional(atom) => any, optional(non_neg_integer) => any}

  @doc """
  Decode DHCP options
  """
  @spec decode(binary, [module]) :: decoded_options
  def decode(opts, modules) do
    opts
    |> decode_bin([])
    |> decode_mod(modules)
    |> Enum.into(%{})
  end

  defp decode_bin("", so_far), do: so_far
  defp decode_bin(<<@option_padding, rest::binary>>, so_far), do: decode(rest, so_far)
  defp decode_bin(<<@option_finish, _::binary>>, so_far), do: so_far
  defp decode_bin(<<code, len, value::binary-size(len), rest::binary>>, so_far) do
    decode_bin(rest, [{code, value} | so_far])
  end

  defp decode_mod(opts, []), do: opts
  defp decode_mod(opts, [module | rest]) do
    opts
    |> Enum.map(&module.decode/1)
    |> decode_mod(rest)
  end

  @doc """
  Encode the specified list of options to a binary for a DHCP packet.
  """
  @spec encode(Keyword.t | Map.t, [module]) :: iolist
  def encode(options, []), do: encode(options)
  def encode(options, [parser | rest]) do
    options
    |> Stream.map(&parser.encode/1)
    |> encode(rest)
  end
  @spec encode(Enumerable.t) :: iolist
  def encode(options) do
    [Enum.filter(options, &is_binary/1) | <<@option_finish>>]
  end

  #codec functions.

  @spec decode_integer(binary) :: integer
  def decode_integer(<<a::32>>), do: a
  @spec encode_integer(typecode, integer) :: binary
  def encode_integer(type, a) when is_integer(a), do: <<type, 4, a::32>>

  @spec decode_short(binary) :: integer
  def decode_short(<<a::16>>), do: a
  @spec encode_short(typecode, integer) :: binary
  def encode_short(type, a) when is_integer(a), do: <<type, 2, a::16>>

  @spec decode_byte(binary) :: byte
  def decode_byte(<<a>>), do: a
  @spec encode_byte(typecode, byte) :: binary
  def encode_byte(type, a) when is_integer(a), do: <<type, 1, a>>

  @spec decode_ip(binary) :: Utils.ip4
  def decode_ip(<<a, b, c, d>>), do: {a, b, c, d}
  @spec encode_ip(typecode, Utils.ip4) :: binary
  def encode_ip(type, {a, b, c, d}), do: <<type, 4, a, b, c, d>>

  @spec decode_iplist(binary) :: [Utils.ip4]
  def decode_iplist(<<>>), do: []
  def decode_iplist(<<a, b, c, d>> <> rest) do
    [{a, b, c, d} | decode_iplist(rest)]
  end
  @spec encode_iplist(typecode, [Utils.ip4]) :: binary
  def encode_iplist(type, list) when is_list(list) do
    data = list
    |> Enum.map(fn {a, b, c, d} -> <<a, b, c, d>> end)
    |> IO.iodata_to_binary

    IO.iodata_to_binary([type, byte_size(data), data])
  end

  @spec decode_string(binary) :: binary
  def decode_string(bin), do: bin
  @spec encode_string(typecode, binary) :: binary
  def encode_string(type, value), do: <<type, byte_size(value), value::binary>>

  @spec decode_boolean(binary) :: boolean
  def decode_boolean(<<0>>), do: false
  def decode_boolean(_), do: true
  @spec encode_boolean(typecode, boolean | integer) :: binary
  def encode_boolean(type, true), do: <<type, 1, 1>>
  def encode_boolean(type, false), do: <<type, 1, 0>>
  def encode_boolean(type, value), do: <<type, 1, value>>

  @spec decode_uuid(binary) :: String.t
  def decode_uuid(val), do: UUID.binary_to_string!(val)
  @spec encode_uuid(typecode, String.t) :: binary
  def encode_uuid(type, val) when :erlang.size(val) == 36 do
    encode_string(type, UUID.string_to_binary!(val))
  end
  def encode_uuid(type, val) when :erlang.size(val) == 16 do
    encode_string(type, val)
  end
end

defmodule ExDhcp.OptionsApi do
  alias ExDhcp.Options

  @callback decode({Options.typecode, binary}) :: {atom, term} | {Options.typecode, binary}
  @callback decode({atom, term})               :: {atom, term}
  @callback encode({atom, term})               :: {atom, term} | binary
  @callback encode({Options.typecode, binary}) :: {Options.typecode, binary}
end

defmodule ExDhcp.OptionsMacro do

  @options_encodable [:ip, :iplist, :string, :uuid, :integer, :short, :byte, :boolean]

  defp encode_fn(at_form, style, _) when style in @options_encodable do
    quote do Options.unquote(:"encode_#{style}")(unquote(at_form), value) end
  end
  defp encode_fn(at_form, style, context) do
    quote do
      Options.encode_string(
        unquote(at_form),
        unquote(context).unquote(:"encode_#{style}")(value))
    end
  end

  defp decode_fn(style, _context) when style in @options_encodable do
    quote do Options.unquote(:"decode_#{style}")(value) end
  end
  defp decode_fn(style, context) do
    quote do unquote(context).unquote(:"decode_#{style}")(value) end
  end

  @spec at_form(atom) :: Macro.t
  def at_form(name) do
    {:@, [context: Elixir, import: Kernel], [{name, [context: Elixir], Elixir}]}
  end

  @spec encode_atom({atom, atom}, module) :: Macro.t
  def encode_atom({name, style}, context) do
    at_form = at_form(name)
    quote do
      def encode({unquote(name), value}), do: unquote(encode_fn(at_form, style, context))
    end
  end

  @spec encode_atval({atom, atom}, module) :: Macro.t
  def encode_atval({name, style}, context) do
    at_form = at_form(name)
    quote do
      def encode({unquote(at_form), binary}) when is_binary(binary) do
        <<unquote(at_form), :erlang.size(binary)>> <> binary
      end
      def encode({unquote(at_form), value}), do: unquote(encode_fn(at_form, style, context))
    end
  end

  @spec decode({atom, atom}, module) :: Macro.t
  def decode({name, style}, context) do
    at_form = at_form(name)
    quote do
      def decode({unquote(at_form), value}), do: {unquote(name), unquote(decode_fn(style, context))}
    end
  end

  defmacro options(options_list) do
    context = __CALLER__.module
    atom_encoder = Enum.map(options_list, &encode_atom(&1, context))
    atval_encoder = Enum.map(options_list, &encode_atval(&1, context))
    decoder = Enum.map(options_list, &decode(&1, context))
    quote do
      alias ExDhcp.Options

      @spec encode({atom, term})               :: {atom, term} | binary
      @spec encode({Options.typecode, binary}) :: {Options.typecode, binary}
      unquote_splicing(atom_encoder)
      unquote_splicing(atval_encoder)
      def encode(any), do: any

      @spec decode({Options.typecode, binary}) :: {atom, term} | {Options.typecode, binary}
      @spec decode({atom, term})               :: {atom, term}
      unquote_splicing(decoder)
      def decode(any), do: any
    end
  end
end
