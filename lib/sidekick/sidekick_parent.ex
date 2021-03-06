defmodule Sidekick.Parent do
  use Parent.GenServer

  def start_link([parent_node, spec]) do
    Parent.GenServer.start_link(__MODULE__, [parent_node, spec])
  end

  def init([parent_node, spec]) do
    Node.monitor(parent_node, true)
    # Parent.Supervisor.start_link(spec)
    {:ok, nil}
  end

  def handle_info({:nodedown, _node}, _state) do
    Parent.shutdown_all()
    {:stop, "Parent node down"}
  end

  def terminate([_reason, _state]) do
    :init.stop()
  end
end
