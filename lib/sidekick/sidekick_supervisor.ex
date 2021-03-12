defmodule Sidekick.Supervisor do
  use Parent.GenServer
  require Logger

  def start_link(args) do
    Parent.GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init([parent_node, child_specs]) do
    Node.monitor(parent_node, true)
    Enum.each(child_specs, fn spec -> Parent.start_child(Parent.child_spec(spec)) end)
    {:ok, nil}
  end

  @impl true
  def handle_info({:nodedown, _node}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _pid, _reason}, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, state) do
    Logger.debug("Termination #{__MODULE__}")
    Parent.shutdown_all()
    :init.stop()
    state
  end
end
