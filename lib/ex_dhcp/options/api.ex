defmodule ExDhcp.Options.Api do

  @moduledoc """
  TODO: needs documentation
  """

  alias ExDhcp.Options

  @callback decode({Options.typecode, binary}) :: {atom, term} | {Options.typecode, binary}
  @callback decode({atom, term})               :: {atom, term}
  @callback encode({atom, term})               :: {atom, term} | binary
  @callback encode({Options.typecode, binary}) :: {Options.typecode, binary}
end
