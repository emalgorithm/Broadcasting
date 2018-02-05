defmodule System3.Peer do
  def run(system, peer_index, n_peers, max_broadcast, timeout) do
    peers = 0..n_peers-1
    pl = spawn PerfectLink, :run, []
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

defmodule System3.App do

  def init(id, system, beb, n_peers, max_broadcast, timeout) do
    app_id = self()
    spawn (fn -> receive do after timeout -> send app_id, {:stop} end end)

    initial_stats = List.duplicate(0, n_peers)
    run(id, system, beb, initial_stats, initial_stats, max_broadcast)
  end

  # Max broadcasts reached
  def run(id, system, beb, received_status, sent_status, 0) do
    receive do
      {:beb_deliver, {from, _}} -> run(id, system, beb,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, 0)
      {:stop} -> send system, {:done, id, sent_status, received_status}
    end
  end

  def run(id, system, beb, received_status, sent_status, broadcast_left) do
    receive do
      {:beb_deliver, {from, _}} -> run(id, system, beb,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, broadcast_left)
      {:stop} -> send system, {:done, id, sent_status, received_status}
      after 0 ->
        send beb, {:beb_broadcast, {id, "hello"}}
        run(id, system, beb, received_status, Enum.map(sent_status, &(&1 + 1)), broadcast_left - 1)
    end
  end
end
