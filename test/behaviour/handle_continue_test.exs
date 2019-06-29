defmodule DhcpTest.Behaviour.HandleContinueTest do
  #
  #  tests that the handle_continue behaviour works as intended.
  #
  use ExUnit.Case, async: true

  @moduletag [handle_continue: true, behaviour: true]

  describe "when overriding handle_continue" do
    defmodule BasicCont do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.with_port(0)

      @impl true
      def handle_call(any, from, pid) do
        send(pid, {:recv, any})
        {:noreply, pid, {:continue, from}}
      end

      @impl true
      def handle_continue(from, pid) do
        send(pid, :continued)
        GenServer.reply(from, :bar)
        {:noreply, pid}
      end
    end

    test "basic continue functionality works" do
      {:ok, pid} = BasicCont.start_link()

      assert :bar == GenServer.call(pid, :foo)
      assert_received({:recv, :foo})
      assert_received(:continued)
    end

    defmodule ChgCont do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.with_port(0)

      @impl true
      def handle_call(new_val, _from, old_val) do
        {:reply, old_val, old_val, {:continue, new_val}}
      end

      @impl true
      def handle_continue(new_val, _) do
        {:noreply, new_val}
      end
    end

    test "state-changing continue functionality works" do
      {:ok, pid} = ChgCont.start_link()

      assert self() == GenServer.call(pid, :foo)
      assert :foo == GenServer.call(pid, :bar)
    end
  end
end
