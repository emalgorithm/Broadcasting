defmodule System4.Peer do
  def run(system, peer_index, n_peers, max_broadcast) do
    peers = 0..n_peers-1
    pl = spawn System4.LossyLink, :run, [peer_index]
    beb = spawn BEB, :run, [peer_index, peers, pl]
    send system, {peer_index, pl}
    receive do
      {:ready} ->
        initial_stats = List.duplicate(0, n_peers)
        app = spawn System3.App, :run,
          [peer_index, beb, initial_stats, initial_stats, max_broadcast]
        send beb, {:bind_app, app}
        send pl, {:bind_app, beb}
    end
  end
end

defmodule System4.LossyLink do
  def run(id, reliability \\ 50, app \\ {}, links \\ []) do
    receive do
      {:bind_links, links} -> run(id, reliability, app, links)
      {:bind_app, app} -> run(id, reliability, app, links)
      {:pl_send, msg, dest} ->
        if Enum.random(1..100) <= reliability do
          send Enum.at(links, dest), {msg, id}
        end
        run(id, reliability, app, links)
      {msg, from} ->
        send app, {:pl_deliver, msg, from}
        run(id, reliability, app, links)
    end
  end
end
