defmodule System6.Peer do
  def run(system, peer_index) do
    reliability = 50
    pl = spawn LossyLink, :run, [reliability]
    beb = spawn BEB, :run, [pl]
    rb = spawn RB, :run, [beb]
    send system, {peer_index, pl}
    receive do
      {:ready, max_broadcast, n_peers, timeout} ->
        app = spawn System6.App, :init,
          [peer_index, system, rb, n_peers, max_broadcast, timeout]
        send rb, {:bind_app, app}
        send beb, {:bind_app, rb, 0..n_peers-1}
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

defmodule System6.App do

  def init(id, system, rb, n_peers, max_broadcast, timeout) do
    app_id = self()
    spawn (fn -> receive do after timeout -> send app_id, {:stop} end end)

    initial_stats = List.duplicate(0, n_peers)
    run(id, system, rb, initial_stats, initial_stats, max_broadcast)
  end

  # Max broadcasts reached
  def run(id, system, rb, received_status, sent_status, 0) do
    receive do
      {:rb_deliver, {from, _}} -> run(id, system, rb,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, 0)
      {:stop} -> send system, {:done, id, sent_status, received_status}
    end
  end

  def run(id, system, rb, received_status, sent_status, broadcast_left) do
    receive do
      {:rb_deliver, {from, _}} -> run(id, system, rb,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, broadcast_left)
      {:stop} -> send system, {:done, id, sent_status, received_status}
      after 0 ->
        # Make sure the sent message is unique by including the number of
        # broadcasts left for this process as well as it's unique id
        send rb, {:rb_broadcast, {id, broadcast_left}}
        run(id, system, rb, received_status, Enum.map(sent_status, &(&1 + 1)), broadcast_left - 1)
    end
  end
end
