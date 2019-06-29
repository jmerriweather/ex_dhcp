defmodule DhcpTest.Behaviour.CommonDhcp do

  # a "common" dhcp module that is used by several of the
  # handler testing suites

  defmacro with_port(port, macro_opts \\ []) do
    quote do
      use ExDhcp, unquote(macro_opts)
      def start_link, do: ExDhcp.start_link(__MODULE__, self(), port: unquote(port))
      def start_link(start, opts) do
        ExDhcp.start_link(__MODULE__, start, opts ++ [port: unquote(port)])
      end

      @impl true
      def init(pid), do: {:ok, pid}
      @impl true
      def handle_discover(_ , _, _, _), do: :error
      @impl true
      def handle_request(_ , _, _, _), do: :error
      @impl true
      def handle_decline(_ , _, _, _), do: :error
    end
  end
end
