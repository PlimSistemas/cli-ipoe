function username(pkt)
	local circuit_id = pkt:agent_circuit_id()
	return circuit_id 
end


