defmodule DhcpTest.Behaviour.HandleCallTest do
  #
  #  tests that the handle_call behaviour works as intended.
  #
  use ExUnit.Case, async: true

  @moduletag [handle_call: true, behaviour: true]

  describe "when overriding handle_call" do

    defmodule BasicCall do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.with_port(0)

      @impl true
      def handle_call(any, _from, pid) do
        send(pid, {:recv, any})
        {:reply, :foo, pid}
      end
    end

    test "handle_call is called, and correctly responds" do
      {:ok, pid} = BasicCall.start_link()
      assert :foo == GenServer.call(pid, :bar)
      assert_receive {:recv, :bar}
    end

    defmodule ChgCall do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.with_port(0)

      @impl true
      def handle_call({:chg, any}, _from, old_state) do
        {:reply, old_state, any}
      end
    end

    test "changes to the state are respected" do
      {:ok, pid} = ChgCall.start_link()
      GenServer.call(pid, {:chg, :foo})
      assert :foo == GenServer.call(pid, {:chg, :bar})
    end

  end
end
