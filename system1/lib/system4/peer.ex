defmodule System4.Peer do
  def run(system, peer_index, n_peers, max_broadcast, timeout) do
    peers = 0..n_peers-1
    reliability = 50
    pl = spawn LossyLink, :run, [peer_index, reliability]
    beb = spawn BEB, :run, [peers, pl]
    send system, {peer_index, pl}
    receive do
      {:ready} ->
        app = spawn System3.App, :init,
          [peer_index, system, beb, n_peers, max_broadcast, timeout]
        send beb, {:bind_app, app}
        send pl, {:bind_app, beb}
    end
  end
end
