defmodule System3.Peer do
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
    end
  end
end

# defmodule System3.PerfectLink do
#   def run(id, app \\ {}, links \\ []) do
#     receive do
#       {:bind_links, links} -> run(id, app, links)
#       {:bind_app, app} -> run(id, app, links)
#       {:pl_send, msg, dest} ->
#         send Enum.at(links, dest), {msg, id}
#         run(id, app, links)
#       {msg, from} ->
#         send app, {:pl_deliver, msg, from}
#         run(id, app, links)
#     end
#   end
# end

defmodule BEB do
  def run(id, peers, pl, app \\ {}) do
    receive do
      {:bind_app, app} -> run(id, peers, pl, app)
      {:beb_broadcast, msg} -> 
        for p <- peers do
          send pl, {:pl_send, msg, p}
        end
        run(id, peers, pl, app)
      {:pl_deliver, msg, from} -> 
        send app, {:beb_deliver, msg, from}  
        run(id, peers, pl, app)
    end
  end
end

defmodule System3.App do

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
