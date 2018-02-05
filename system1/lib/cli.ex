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
    Starting System 1 with arguments
      max_messages: #{max_messages}
      n_peers: #{n_peers}
      timeout: #{timeout}
    """

    case n do
      1 -> System1.main(max_messages, n_peers, timeout)
      2 -> System2.main(max_messages, n_peers, timeout)
      3 -> System3.main(max_messages, n_peers, timeout)
    end
  end
end
