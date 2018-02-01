defmodule System1 do
  def main do
    num_of_peers = 5
    timeout = 3000

    peers = 
    for i <- 0..num_of_peers, do: spawn(Peer, :start, [self(), i])

    for peer <- peers, do: Process.send_after(peer, :timeout, timeout)

    for peer <- peers, do: send peer, {:neighbours, peers}

    for peer <- peers, do: send peer, {:broadcast, 1000}

    listen(num_of_peers, 0)
    
  end

  def listen(num_of_peers, peer_counter) do
    receive do
      {:done, peer_index, sent_status, received_status} ->
        status = List.zip([sent_status, received_status])
        IO.puts("Peer, S R:  #{peer_index} #{inspect status}")
        #IO.inspect(status)
        if peer_counter < num_of_peers - 1 do
          listen(num_of_peers, peer_counter + 1)
        end 
    end
  end

end
