function username(pkt)
	local circuit_id = pkt:agent_circuit_id()
	return circuit_id 
end

function test(pkt)
	local res = ""
	for i = 1, 20 do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end