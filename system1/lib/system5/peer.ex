defmodule System5.Peer do
  def run(system, peer_index, n_peers, max_broadcast, timeout) do
    peers = 0..n_peers-1
    reliability = 50
    pl = spawn LossyLink, :run, [reliability]
    beb = spawn BEB, :run, [peers, pl]
    send system, {peer_index, pl}
    receive do
      {:ready} ->
        app = spawn System3.App, :init,
          [peer_index, system, beb, n_peers, max_broadcast, timeout]
        send beb, {:bind_app, app}
        send pl, {:bind_app, beb}
        if peer_index == 2 do
          receive do
            after 5 ->
              Process.exit(app, :kill)
          end
        end
    end

  end
end
