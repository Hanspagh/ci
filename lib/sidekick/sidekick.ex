defmodule Sidekick do
  @spec start(atom) :: {:error, any} | {:ok, atom, pid}
  def start(node_name \\ :docker, child_spec \\ [{Ci.Docker, []}]) do
    parent_node = Node.self()
    wait_for_sidekick(node_host_name(node_name), parent_node, child_spec)
  end

  @spec call(atom, atom, atom, [any]) :: any
  def call(name \\ :docker, module, method, args) do
    :rpc.block_call(node_host_name(name), module, method, args)
  end

  @spec cast(atom, atom, atom, list) :: true
  def cast(name \\ :docker, module, method, args) do
    :rpc.cast(node_host_name(name), module, method, args)
  end

  @spec start_sidekick([node, ...]) :: :ok
  def start_sidekick([parent_node]) do
    Node.connect(parent_node)
    :ok
  end

  defp node_host_name(name) do
    hostname = Node.self() |> Atom.to_string() |> String.split("@") |> List.last()
    :"#{name}@#{hostname}"
  end

  defp wait_for_sidekick(sidekick_node, parent_node, child_spec) do
    :net_kernel.monitor_nodes(true)
    command = start_node_command(sidekick_node, parent_node)
    Port.open({:spawn, command}, [:stream])

    receive do
      {:nodeup, ^sidekick_node} ->
        # wait for node to be really up
        :timer.sleep(500)

        case call(:docker, Sidekick.Supervisor, :start_link, [[parent_node, child_spec]]) do
          {:ok, pid} ->
            {:ok, sidekick_node, pid}

          error ->
            Node.spawn(sidekick_node, :init, :stop, [])
            {:error, error}
        end
    after
      5000 ->
        # Shutdown node if we never received a response
        Node.spawn(sidekick_node, :init, :stop, [])
        {:error, :timeout}
    end
  end

  defp start_node_command(sidekick_node, parent_node) do
    {:ok, command} = :init.get_argument(:progname)
    paths = Enum.join(:code.get_path(), " , ")

    base_args = "-noinput -name #{sidekick_node}"

    priv_dir = :code.priv_dir(:ci)
    boot_file_args = "-boot #{priv_dir}/node"

    cookie = Node.get_cookie()
    cookie_arg = "-setcookie #{cookie}"

    paths_arg = "-pa #{paths}"

    command_args = "-s Elixir.Sidekick start_sidekick #{parent_node}"

    args = "#{base_args} #{boot_file_args} #{cookie_arg} #{paths_arg} #{command_args}"

    "#{command} #{args}"
  end
end
