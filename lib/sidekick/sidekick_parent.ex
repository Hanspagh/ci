defmodule Sidekick.Parent do
  use GenServer, restart: :transient, shutdown: 10_000

  def start_link([parent_node, spec]) do
    GenServer.start_link(__MODULE__, [parent_node, spec], name: __MODULE__)
  end

  def init([parent_node, spec]) do
    Node.monitor(parent_node, true)
    IO.inspect("monitor node #{inspect(parent_node)}")
    {:ok, pid} = Supervisor.start_link(spec, strategy: :one_for_one, name: Sidekick.Supervisor)
    IO.inspect("supervisor up #{inspect(pid)}")
    {:ok, nil}
  end

  def handle_info({:nodedown, node}, _state) do
    IO.inspect("node down #{inspect(node)}")
    Supervisor.stop(Sidekick.Supervisor)
    {:stop, :normal}
  end

  def terminate(_reason, _state) do
    IO.inspect("terminate node down}")
    :init.stop()
  end
end
