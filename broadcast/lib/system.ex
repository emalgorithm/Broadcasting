defmodule BroadcastSystem do
  def main(peer_ids, max_broadcast \\ 1000, n_peers \\ 5, timeout \\ 3000) do
    pl_ids = for i <- 0..n_peers-1 do
      receive do
        {^i, pl} -> pl
      end
    end

    for pl <- pl_ids do
      send pl, {:bind_links, pl_ids}
    end

    for p <- peer_ids do
      send p, {:ready, max_broadcast, n_peers, timeout}
    end

    Process.sleep(timeout) 

    for i <- 0..n_peers-1 do
      receive do
        {:done, ^i, sent_status, received_status} ->
          status = List.zip([sent_status, received_status])
          IO.puts("#{i}: #{inspect status}")
        after 100 -> IO.puts("No reply from process #{i} in 100ms")
      end
    end

  end

end
