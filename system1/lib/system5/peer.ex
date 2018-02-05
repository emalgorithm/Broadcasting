defmodule System5.Peer do
  def run(system, peer_index, n_peers, max_broadcast) do
    peers = 0..n_peers-1
    pl = spawn PerfectLink, :run, [peer_index]
    beb = spawn BEB, :run, [peer_index, peers, pl]
    send system, {peer_index, pl}
    receive do
      {:ready} ->
        initial_stats = List.duplicate(0, n_peers)
        app = spawn System3.App, :run,
          [peer_index, beb, initial_stats, initial_stats, max_broadcast]
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

defmodule System5.App do

  # Max broadcasts reached
  def run(id, beb, received_status, sent_status, 0) do
    receive do
      {:beb_deliver, :stop, system} -> send system, {:done, id, sent_status, received_status}
      {:beb_deliver, _, from} -> run(id, beb,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, 0)
    end
  end

  def run(id, beb, received_status, sent_status, broadcast_left) do
    receive do
      {:beb_deliver, :stop, system} -> send system, {:done, id, sent_status, received_status}
      {:beb_deliver, _, from} -> run(id, beb,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, broadcast_left)
      after 0 ->
        send beb, {:beb_broadcast, {}}
        run(id, beb, received_status, Enum.map(sent_status, &(&1 + 1)), broadcast_left - 1)
    end
  end
end
