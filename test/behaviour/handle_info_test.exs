defmodule DhcpTest.Behaviour.HandleInfoTest do
  #
  #  tests that the handle_info behaviour works as intended.
  #
  use ExUnit.Case, async: true

  @moduletag [handle_info: true, behaviour: true]

  describe "when overriding handle_info" do

    defmodule NonUdp do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.with_port(0)

      @impl true
      def handle_info(any, pid) do
        send(pid, {:recv, any})
        {:noreply, pid}
      end
    end

    test "we can trap non-udp packets" do
      {:ok, pid} = NonUdp.start_link()
      send(pid, :ping)
      assert_receive {:recv, :ping}
    end

    defmodule YesUdp do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.with_port(32_621)

      @impl true
      def handle_info({:udp, _, _, _, data}, pid) do
        send(pid, {:recv, data})
        {:noreply, pid}
      end
    end

    test "we can trap a udp packet forwarded" do
      {:ok, pid} = YesUdp.start_link()
      send(pid, {:udp, nil, nil, nil, "test"})
      assert_receive {:recv, "test"}
    end

    test "we can trap a generic udp message" do
      {:ok, _} = YesUdp.start_link()
      {:ok, sock} = :gen_udp.open(0)
      :gen_udp.send(sock, {127, 0, 0, 1}, 32_621, "test")
      assert_receive {:recv, "test"}
    end

    defmodule ChgUdp do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.with_port(0)

      @impl true
      def handle_info({:chg, from, new}, old) do
        send(from, {:old_state, old})
        {:noreply, new}
      end
    end

    test "changes to the state are respected" do
      {:ok, pid} = ChgUdp.start_link()
      send(pid, {:chg, self(), :foo})
      assert_receive {:old_state, _}
      send(pid, {:chg, self(), :bar})
      assert_receive {:old_state, :foo}
    end

  end
end
