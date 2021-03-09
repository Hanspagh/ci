defmodule Sidekick.GenServer do
  use GenServer, restart: :transient, type: :supervisor

  def start_link([parent_node]) do
    GenServer.start_link(__MODULE__, [parent_node], name: __MODULE__)
  end

  @impl GenServer
  def init([parent_node]) do
    Node.monitor(parent_node, true)
    IO.inspect("monitor node #{inspect(parent_node)}")
    {:ok, pid} = Ci.Docker.start_link([])
    IO.inspect("child up #{inspect(pid)}")
    {:ok, pid}
  end

  def handle_call(:ping, from, state) do
    {:reply, :pong, state}
  end

  @impl GenServer
  def handle_info({:nodedown, node}, pid) do
    IO.inspect("node down #{inspect(node)}")
    GenServer.stop(pid)
    :timer.sleep(1000)
    {:stop, :normal, nil}
  end

  @impl GenServer
  def terminate(reason, state) do
    # IO.inspect("terminating now")
    :init.stop()
  end
end
