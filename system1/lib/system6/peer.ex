defmodule System6.Peer do
  def run(system, peer_index, n_peers, max_broadcast) do
    peers = 0..n_peers-1
    pl = spawn System4.LossyLink, :run, [peer_index]
    beb = spawn BEB, :run, [peer_index, peers, pl]
    rb = spawn RB, :run, [peer_index, peers, pl]
    send system, {peer_index, pl}
    receive do
      {:ready} ->
        initial_stats = List.duplicate(0, n_peers)
        app = spawn System6.App, :run,
          [peer_index, rb, initial_stats, initial_stats, max_broadcast]
        send rb, {:bind_app, app}
        send beb, {:bind_app, rb}
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

defmodule RB do
  def run(id, peers, beb, app \\ {}, delivered \\ []) do
    receive do
      {:bind_app, app} -> run(id, peers, beb, app)
      {:rb_broadcast, msg} -> 
        send beb, {:beb_broadcast, {msg, id}}
        run(id, peers, beb, app)
      {:beb_deliver, msg, from} -> 
        if !Enum.member?(delivered, msg) do
          send beb, {:beb_broadcast, msg}
          send app, {:rb_deliver, msg, from} 
          run(id, peers, beb, app, [msg | delivered])
        else
          run(id, peers, beb, app, delivered)
        end
    end
  end
end

defmodule System6.App do

  # Max broadcasts reached
  def run(id, rb, received_status, sent_status, 0) do
    receive do
      {:rb_deliver, :stop, system} -> send system, {:done, id, sent_status, received_status}
      {:rb_deliver, _, from} -> run(id, rb,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, 0)
    end
  end

  def run(id, rb, received_status, sent_status, broadcast_left) do
    receive do
      {:rb_deliver, :stop, system} -> send system, {:done, id, sent_status, received_status}
      {:rb_deliver, msg, from} -> 
        IO.puts("message is #{inspect msg}")
        run(id, rb,
        List.update_at(received_status, from, &(&1 + 1)), sent_status, broadcast_left)
      after 0 ->
        send rb, {:rb_broadcast, broadcast_left}
        run(id, rb, received_status, Enum.map(sent_status, &(&1 + 1)), broadcast_left - 1)
    end
  end
end
