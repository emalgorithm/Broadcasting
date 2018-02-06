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
    #  network = opts[:network] || false

    IO.puts """
    Starting System 1 with arguments
      max_messages: #{max_messages}
      n_peers: #{n_peers}
      timeout: #{timeout}
    """

    peer_module = case n do
      1 -> System1.Peer
      2 -> System2.Peer
      3 -> System3.Peer
      4 -> System4.Peer
      5 -> System5.Peer
      6 -> System6.Peer
    end

    if n == 1 do
      peers =
        for i <- 0..n_peers, do: spawn(Peer, :start, [self(), i])
      System1.main(peers, max_messages, n_peers, timeout)
    else
      peer_ids = spawn_peers(peer_module, n_peers, max_messages, timeout)
      BroadcastSystem.main(peer_ids, n_peers, timeout)
    end
  end

  def spawn_peers(peer_module, n_peers, max_messages, timeout) do
    for i <- 0..n_peers-1 do
      spawn peer_module, :run, [self(), i, n_peers, max_messages, timeout]
    end
  end
end
