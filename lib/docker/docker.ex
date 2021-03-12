defmodule Ci.Docker do
  use Parent.GenServer
  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})
  end

  @impl GenServer
  def init([]) do
    {:ok, %{}}
  end

  def run(name) do
    GenServer.call({:global, __MODULE__}, {:start, name})
  end

  def stop() do
    GenServer.call({:global, __MODULE__}, :stop)
  end

  @impl GenServer
  def handle_call({:start, name}, {from, _ref}, state) do
    {id, _} = System.cmd("docker", ["run", "-dt", name])
    container_id = String.trim(id)
    monitor_ref = Process.monitor(from)
    state = Map.put(state, from, {container_id, monitor_ref})
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:stop, {pid, _ref}, state) do
    {{container_id, monitor_ref}, state} = Map.pop(state, pid)
    cleanup(container_id, monitor_ref)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:down, pid}, state) do
    {{container_id, monitor_ref}, state} = Map.pop(state, pid)
    cleanup(container_id, monitor_ref)
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    Logger.debug("Termination #{__MODULE__}")

    Enum.each(state, fn {_pid, {container_id, monitor_ref}} ->
      cleanup(container_id, monitor_ref)
    end)

    state
  end

  defp cleanup(container_id, monitor_ref) do
    Process.demonitor(monitor_ref)
    System.cmd("docker", ["rm", "-f", container_id])
  end
end
