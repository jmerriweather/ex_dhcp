defmodule DhcpTest.Behaviour.HandleCastTest do
  #
  #  tests that the handle_call behaviour works as intended.
  #
  use ExUnit.Case, async: true

  @moduletag [handle_cast: true, behaviour: true]

  describe "when overriding handle_cast" do

    defmodule BasicCast do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.with_port(0)

      @impl true
      def handle_cast(any, pid) do
        send(pid, {:recv, any})
        {:noreply, pid}
      end
    end

    test "handle_cast is called" do
      {:ok, pid} = BasicCast.start_link()
      GenServer.cast(pid, :bar)
      assert_receive {:recv, :bar}
    end

    defmodule ChgCast do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.with_port(0)

      @impl true
      def handle_cast({:chg, from, new_state}, old_state) do
        send(from, {:was, old_state})
        {:noreply, new_state}
      end
    end

    test "changes to the state are respected" do
      {:ok, pid} = ChgCast.start_link()
      GenServer.cast(pid, {:chg, self(), :foo})
      assert_receive {:was, _}
      GenServer.cast(pid, {:chg, self(), :bar})
      assert_receive {:was, :foo}
    end

  end
end
