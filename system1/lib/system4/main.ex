defmodule System4 do
  def main(max_broadcast \\ 1000, n_peers \\ 5, timeout \\ 3000) do
    peer_ids = for i <- 0..n_peers-1 do
      spawn System4.Peer, :run, [self(), i, n_peers, max_broadcast]
    end

    pl_ids = for i <- 0..n_peers-1 do
      receive do
        {^i, pl} -> pl
      end
    end

    for pl <- pl_ids do
      send pl, {:bind_links, pl_ids}
    end

    for p <- peer_ids do
      send p, {:ready}
    end

    receive do
    after timeout ->
      for pl <- pl_ids do
        send pl, {:stop, self()}
      end
    end

    listen(n_peers, 0)
  end

  def listen(num_of_peers, peer_counter) do
    receive do
      {:done, peer_index, sent_status, received_status} ->
        status = List.zip([sent_status, received_status])
        IO.puts("#{peer_index}: #{inspect status}")
        #IO.inspect(status)
        if peer_counter < num_of_peers - 1 do
          listen(num_of_peers, peer_counter + 1)
        end
    end
  end
end
