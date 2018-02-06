defmodule System1.Peer do
	def run(system, peer_index) do
		receive do
			{:neighbours, neighbours} -> 
				listen(system, peer_index, neighbours)
		end
	end

	def listen(system, peer_index, neighbours) do
		received_status = List.duplicate(0, length(neighbours))
		sent_status = List.duplicate(0, length(neighbours))
		
		receive do
			{:broadcast, max_broadcast} -> broadcast(system, peer_index, neighbours, max_broadcast, received_status, sent_status, 0)
		end
	end

	def broadcast(system, peer_index, neighbours, max_broadcast, received_status, sent_status, broadcast_counter) do
		receive do
			# When receiving message, store it in the dict and then broadcast
			{:message, sender} ->
				broadcast(system, peer_index, neighbours, max_broadcast, List.update_at(received_status, sender, &(&1 + 1)), sent_status, broadcast_counter)
			:timeout ->
				send system, {:done, peer_index, sent_status, received_status}
			after 0 -> 
				# If we have broadcast less than max_broadcast times, keep broadcasting
				sent_status = if broadcast_counter < max_broadcast do
					for neighbour <- neighbours, do: send neighbour, {:message, peer_index}
					for elem <- sent_status, do: elem + 1
				end || sent_status
				broadcast(system, peer_index, neighbours, max_broadcast, received_status, sent_status, broadcast_counter + 1)
		end
	end

end

