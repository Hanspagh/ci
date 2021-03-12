defmodule Sidekick.GenServer do
  use GenServer, restart: :transient, type: :supervisor
  require Logger

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
  def handle_info({:nodedown, _node}, state) do
    Logger.debug("#{__MODULE__} Monitor node went down")
    {:stop, :normal, state}
  end

  @impl GenServer
  def terminate(_reason, pid) do
    Logger.debug("Termination #{__MODULE__}")
    GenServer.stop(pid, :normal)
    :init.stop()
    pid
  end
end
