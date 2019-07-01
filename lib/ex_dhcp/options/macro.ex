
defmodule ExDhcp.Options.Macro do

  @moduledoc """
  TODO: needs documentation
  """

  #
  #  TODO: Macro should emit documentation for the macros it's generating.
  #

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
