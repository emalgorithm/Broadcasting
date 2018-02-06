defmodule System4.Peer do
  def run(system, peer_index) do
    reliability = 50
    pl = spawn LossyLink, :run, [reliability]
    beb = spawn BEB, :run, [pl]
    send system, {peer_index, pl}
    receive do
      {:ready, max_broadcast, n_peers, timeout} ->
        app = spawn System3.App, :init,
          [peer_index, system, beb, n_peers, max_broadcast, timeout]
        send beb, {:bind_app, app, 0..n_peers-1}
        send pl, {:bind_app, beb}
    end
  end
end
