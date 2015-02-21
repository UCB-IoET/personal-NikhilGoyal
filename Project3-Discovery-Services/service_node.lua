require "cord"

local my_id = 0

print("\n\n\tSERVICE NODE "..my_id.."\n\n")

ipaddr = storm.os.getipaddr()
ipaddrs = string.format("%02x%02x:%02x%02x:%02x%02x:%02x%02x::%02x%02x:%02x%02x:%02x%02x:%02x%02x",
			ipaddr[0],
			ipaddr[1],ipaddr[2],ipaddr[3],ipaddr[4],
			ipaddr[5],ipaddr[6],ipaddr[7],ipaddr[8],	
			ipaddr[9],ipaddr[10],ipaddr[11],ipaddr[12],
			ipaddr[13],ipaddr[14],ipaddr[15])

print("ip addr\n", ipaddrs)

local service_messages = {
    servTemp = {s = "subscribeToTemp", desc = "temp", service_type = {"prof"} },
}

local is_master = true
local previous_master = false

local enable_switch = true

service_node_table = {}
recv_ack = {}
switch_master_handle = {}
switch_ack = {}
service_node_count = 1

add_master_service = function ()
	if (is_master == true) then
		service_node_table[my_id] = {}
		service_node_table[my_id].from = ipaddrs
		service_node_table[my_id].student = true
		service_node_table[my_id].prof = true
		service_node_count = service_node_count + 1
	end
end

add_master_service()

broadcast_listen_port = 1611

service_node_listen_port = 1612

service_node_ack_listen_port = 1613

client_port = 1614
client_port_ack = 1615
--client_service_port = 1616

master_ip = -1
master_id = -1

-- Master socket
-- Recievs a NEW CLIENT OR A NEW SERVICE node message
master = function()
   msock = storm.net.udpsocket(broadcast_listen_port, 
			       function(payload, from, port)
				local msg = storm.mp.unpack(payload)
			       	if (is_master == true) then
					if (msg.desc == "NEW_SERVICE") then
						print("Recving new service\n")
						if (service_node_table[msg.id] == nil) then
							service_node_table[msg.id] = {}
							service_node_table[msg.id].from = from
							if (msg.student ~= nil) then
								service_node_table[msg.id].student = true
							end
							if (msg.prof ~= nil) then
								service_node_table[msg.id].prof = true
							end
							if (msg.staff ~= nil) then
								service_node_table[msg.id].staff = true
							end
							service_node_count = service_node_count + 1
						end

						local msg_ack = {}
						msg_ack.id = my_id
						msg_ack.desc = "NEW_SERVICE_ACK"
						local payload_ack = storm.mp.pack(msg_ack)
						storm.net.sendto(msock, payload_ack, from, service_node_listen_port)
					elseif (msg.desc == "NEW_CLIENT") then
						for curr_id, curr_node in pairs(service_node_table) do
							if (curr_id ~= my_id) then
								if (curr_node[msg.client_table] ~= nil) then
									local msg_service = {}
									msg_service.id = my_id
									msg_service.desc = "NEW_CLIENT_REQUEST"
									msg_service.client_type = msg.client_type
									msg_service.client_ip = from
									local payload_service = storm.mp.pack(msg_service)
									recv_ack[curr_node.from] = storm.os.invokePeriodically(500*storm.os.MILLISECOND, function () storm.net.sendto(msock,payload_service, curr_node.from, service_node_listen_port) end) 
								end
							end
						end
						local msg_client = {}	
						msg_client.id=my_id
						msg_client.desc = "SERVICE"
						msg_client.service = {name = "servTemp", s = "subscribeToTemp", desc = "temp"}
						msg_client.master = true
						local payload_client = storm.mp.pack(msg_client)
						client_ack_handle = storm.os.invokePeriodically(500*storm.os.MILLISECOND, function () storm.net.sendto(msock,payload_client, from, client_port) end) 
					end
					
				end
			       end)
end

--this socket just maskes sure the master's recieves the new service node's ack
recv_service_ack = function()
	rssock = storm.net.udpsocket(service_node_ack_listen_port, 
			       function(payload, from, port)
					if (recv_ack[from] ~= nil) then
						storm.os.cancel(recv_ack[from])
					end
				end)
end

--client and service node comm
client_comm = function()
	rcasock = storm.net.udpsocket(client_port_ack, 
			       function(payload, from, port)
					local msg = storm.mp.unpack(payload)
					if (msg.desc == "RECV_SERVICE") then
						storm.os.cancel(client_ack_handle)
					elseif(msg.desc == "INVOKE_SERVICE") then
						local msg_client = {}
						msg_client.id = my_id
						msg_client.desc = "INVOKE_SERVICE_ACK"
						msg_client.payload = "SUCCESS"
						local payload_client = storm.mp.pack(msg_client_payload)
						client_invoke_service_handle = storm.os.invokePeriodically(500*storm.os.MILLISECOND, function () storm.net.sendto(rcasock,payload_client, from, client_port) end)
					elseif(msg.desc == "INVOKE_SERVICE_ACK") then
						if (client_invoke_service_handle ~= nil) then
							storm.os.cancel(client_invoke_service_handle)
						end
					end
				end)
end


master()
recv_service_ack()
client_comm()

--master and service comm
master_service_comm = function()
mssock = storm.net.udpsocket(service_node_listen_port, 
			       function(payload, from, port)
					local msg = storm.mp.unpack(payload)
					if (msg.desc == "NEW_SERVICE_ACK") then
						print("Receiving new service ack")
						master_ip = from
						master_id = msg.id
						storm.os.cancel(regular_service_handle)
					elseif (msg.desc == "NEW_CLIENT_REQUEST") then
						local msg_client = {}	
						msg_client.id=my_id
						msg_client.desc = "SERVICE"
						msg_client.service = {name = "servTemp", s = "subscribeToTemp", desc = "temp", service_type = msg.client_type }
						local payload_client = storm.mp.pack(msg_client)
						client_ack_handle = storm.os.invokePeriodically(500*storm.os.MILLISECOND, function () storm.net.sendto(mssock,payload_client, from, client_port) end) 
					elseif (msg.desc == "SWITCH_MASTER") then
						print("RECIEVED PAYLOAD FOR MASTER SWITCH "..msg.service_node_id.."  "..msg.service_node_ip.."\n")
						if (service_node_table[msg.service_node_id] == nil) then
							service_node_table[msg.service_node_id] = {}
							service_node_table[msg.service_node_id].from = msg.service_node_ip
							if (msg.student ~= nil) then
								service_node_table[msg.service_node_id].student = true
							end
							if (msg.prof ~= nil) then
								service_node_table[msg.service_node_id].prof = true
							end
							if (msg.staff ~= nil) then
								service_node_table[msg.service_node_id].staff = true
							end
							service_node_count = service_node_count + 1
						end
						local msg_ack = {}
						msg_ack.id = my_id
						msg_ack.desc = "SWITCH_MASTER_ACK"
						msg_ack.service_node_id = msg.service_node_id
						local payload_ack = storm.mp.pack(msg_ack)
						storm.net.sendto(mssock, payload_ack, from, service_node_listen_port)
					elseif (msg.desc == "SWITCH_MASTER_ACK") then
						print("Recived MASTER SWITCH ACK for ID "..msg.service_node_id)
							storm.os.cancel(switch_master_handle[msg.service_node_id])
							switch_ack[msg.service_node_id] = 1
							local got_all_ack = false
							for key, value in pairs(service_node_table) do
								if (switch_ack[key] == nil or switch_ack[key] == 0) then 
									return
								end
							end
							got_all_ack = true
							if (got_all_ack == true) then
								for key, value in pairs(service_node_table) do
									switch_ack[key] = 0
								end
								is_master = false
								enable_switch = true
								local msg_switch = {}
								msg_switch.id = my_id
								msg_switch.desc = "READY_SWITCH_MASTER"
								local payload_new_master = storm.mp.pack(msg_switch)
									switch_handle = storm.os.invokePeriodically(1*storm.os.SECOND, 											function () 
											print("Sending READY_SWITCH")
											if (master_id == curr_id) then
												service_node_table[new_master].from = master_ip
											end
											storm.net.sendto(msock,payload_new_master,service_node_table[new_master].from, service_node_listen_port) end) 
							end
						
					elseif (msg.desc == "READY_SWITCH_MASTER") then
						print("RECIEVED READY_SWITCH")
						is_master = true
						local msg_ack = {}
						msg_ack.id = my_id
						msg_ack.desc = "READY_SWITCH_MASTER_ACK"
						local payload_ack = storm.mp.pack(msg_ack)
						storm.net.sendto(msock,payload_ack,from, service_node_listen_port)
					elseif (msg.desc == "READY_SWITCH_MASTER_ACK") then
						print("RECEIVED READY_SWITCH_ACK")
						storm.os.cancel(switch_handle)
					end
				end)
end

master_service_comm()

if (is_master == false) then
	local new_service_message = {}
	new_service_message.id = my_id
	new_service_message.desc = "NEW_SERVICE"
	new_service_message.student = true
	local new_service_payload = storm.mp.pack(new_service_message)
	regular_service_handle = storm.os.invokePeriodically(500*storm.os.MILLISECOND, function () 
								print("Sending new service\n")
								storm.net.sendto(mssock,new_service_payload,"ff02::1", broadcast_listen_port) end)

end

--Switching master node
local switch_ack = {}
storm.os.invokePeriodically(120*storm.os.SECOND, function () 
							if (is_master == true and enable_switch == true) then
								print("Time to Switch Master\n")
								if (service_node_count >= 2) then
									enable_switch = false
									new_master = (my_id + 1) % (service_node_count - 1)
									for curr_id, curr_node in pairs(service_node_table) do
										print("LOOK "..curr_id)
										switch_ack[curr_id] = 0
									end
									for curr_id, curr_node in pairs(service_node_table) do
										local msg_new_master = {}
										msg_new_master.id = my_id
										msg_new_master.desc = "SWITCH_MASTER"
										msg_new_master.service_node_ip = curr_node.from
										msg_new_master.service_node_id = curr_id
										if (curr_node.student ~= nil) then msg_new_master.student = true end
										if (curr_node.prof ~= nil) then msg_new_master.prof = true end
										if (curr_node.staff ~= nil) then msg_new_master.staff = true end
										local payload_new_master = storm.mp.pack(msg_new_master)
									switch_master_handle[curr_id] =storm.os.invokePeriodically(1*storm.os.SECOND, 											function () 
											print("Sending to new master "..curr_id.."\n")
											if (master_id == curr_id) then
												service_node_table[new_master].from = master_ip
											end
											storm.net.sendto(msock,payload_new_master,service_node_table[new_master].from, service_node_listen_port) end)
									end
								end
							end
end)


cord.enter_loop()
