defmodule System2.Peer do
  def run(system, peer_index, n_peers, max_broadcast, timeout) do
    pl = spawn PerfectLink, :run, [peer_index]
    send system, {peer_index, pl}
    receive do
      {:ready} ->
        app = spawn App, :init,
          [peer_index, system, pl, n_peers, max_broadcast, timeout]
        send pl, {:bind_app, app}
    end
  end
end

defmodule PerfectLink do
  def run(id, app \\ {}, links \\ []) do
    receive do
      {:bind_links, links} -> run(id, app, links)
      {:bind_app, app} -> run(id, app, links)
      {:pl_send, msg, dest} ->
        send Enum.at(links, dest), {msg, id}
        run(id, app, links)
      {msg, from} ->
        send app, {:pl_deliver, msg, from}
        run(id, app, links)
    end
  end
end

defmodule App do
  def init(id, system, pl, n_peers, max_broadcast, timeout) do
    app_id = self()
    spawn (fn -> receive do after timeout -> send app_id, {:stop} end end)

    initial_stats = List.duplicate(0, n_peers)
    run(id, system, pl, 0..n_peers-1, initial_stats, initial_stats, max_broadcast)
  end

  # Max broadcasts reached
  def run(id, system, pl, peers, received_status, sent_status, 0) do
    receive do
      {:pl_deliver, _, from} -> run(id, system, pl, peers,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, 0)
      {:stop} -> send system, {:done, id, sent_status, received_status}
    end
  end

  def run(id, system, pl, peers, received_status, sent_status, broadcast_left) do
    receive do
      {:pl_deliver, _, from} -> run(id, system, pl, peers,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, broadcast_left)
      {:stop} -> send system, {:done, id, sent_status, received_status}
      after 0 ->
        for p <- peers do
          send pl, {:pl_send, 0, p}
        end
        run(id, system, pl, peers, received_status, Enum.map(sent_status, &(&1 + 1)), broadcast_left - 1)
    end
  end
end
