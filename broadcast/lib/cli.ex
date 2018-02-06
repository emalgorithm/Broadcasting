defmodule CLI do
  @moduledoc """

  Usage:
   broadcast_cli --system <num> [options]

  Run a selected version of the broadcast system

  Arguments:
   -s, --system <num> the system version to run; supported systems are [1]

  Options:
   -h, --help
   -m, --max_messages [1000]
   -n, --n_peers      [5]
   -t, --timeout      [3000] ms
  """

  def main(args) do
    args |> parse_args |> run
  end

  defp parse_args(args) do
    {opts, _, _} = OptionParser.parse(args,
      strict: [system: :integer, help: :boolean],
      aliases: [s: :system, h: :help])

    case opts do
      [system: n] -> {:system, n, args}
      _ -> IO.puts @moduledoc
    end
  end

  defp run(:ok) do end

  defp run({:system, n, args}) do
    {opts, _, _} = OptionParser.parse(args,
      strict: [max_messages: :integer,
        n_peers: :integer,
        timeout: :integer,
        network: :boolean],
      aliases: [m: :max_messages, n: :n_peers, t: :timeout])

    max_messages = opts[:max_messages] || 1000
    n_peers = opts[:n_peers] || 5
    timeout = opts[:timeout] || 3000
    network = opts[:network] || false

    IO.puts """
    Starting System #{n} with arguments
      max_messages: #{max_messages}
      n_peers: #{n_peers}
      timeout: #{timeout}
      docker: #{network}
    """

    peer_module = case n do
      1 -> System1.Peer
      2 -> System2.Peer
      3 -> System3.Peer
      4 -> System4.Peer
      5 -> System5.Peer
      6 -> System6.Peer
    end
   
    peer_ids = if network do
      spawn_peers_network(peer_module, n_peers)
    else
      spawn_peers_local(peer_module, n_peers)
    end

    if n == 1 do
      System1.main(peer_ids, max_messages, n_peers, timeout)
    else
      BroadcastSystem.main(peer_ids, max_messages, n_peers, timeout)
    end
  end

  def spawn_peers_local(peer_module, n_peers) do
    for i <- 0..n_peers-1 do
      spawn peer_module, :run, [self(), i]
    end
  end

  def spawn_peers_network(peer_module, n_peers) do
    for i <- 0..n_peers-1 do
      Node.spawn(:'node#{i+1}@container#{i+1}.localdomain', peer_module, :run, [self(), i])
    end 
  end
end
