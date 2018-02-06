defmodule System1 do
  def main(peers, max_broadcast \\ 1000, num_of_peers \\ 5, timeout \\ 3000) do
    #
    # peers =
    #     for i <- 0..num_of_peers, do: Node.spawn(:'node#{i+1}@container#{i+1}.localdomain', Peer, :start, [self(), i])


    for peer <- peers, do: send peer, {:neighbours, peers}

    for peer <- peers, do: send peer, {:broadcast, max_broadcast}

    receive do
      after timeout ->
        for peer <- peers, do: send peer, :timeout
    end

    listen(num_of_peers, 0)

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
