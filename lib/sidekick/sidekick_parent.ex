defmodule Sidekick.Parent do
  use Parent.GenServer, restart: :temporary

  def start_link([parent_node]) do
    Parent.GenServer.start_link(__MODULE__, [parent_node], name: __MODULE__)
  end

  @impl GenServer
  def init([parent_node]) do
    Node.monitor(parent_node, true)
    IO.inspect("monitor node #{inspect(parent_node)}")
    {:ok, pid} = Parent.start_child(Parent.child_spec({Ci.Docker, []}))
    IO.inspect("child up #{inspect(pid)}")
    {:ok, pid}
  end

  def handle_info({:nodedown, node}, pid) do
    IO.inspect("node down #{inspect(node)}")
    Parent.shutdown_child(pid)
    {:stop, :normal, pid}
  end

  def handle_info({:EXIT, _pid, _reason}, state), do: {:noreply, state}

  @impl GenServer
  def terminate(reason, state) do
    IO.inspect("terminating now #{inspect(reason)} #{inspect(state)} ")
    :init.stop()
  end
end
