--[[
   echo client as server
   currently set up so you should start one or another functionality at the
   stormshell
--]]

require "cord" -- scheduler / fiber library

print("echo test")

local server_id = "controller"
local service_table = {}

local service_count = 1

ipaddr = storm.os.getipaddr()
ipaddrs = string.format("%02x%02x:%02x%02x:%02x%02x:%02x%02x::%02x%02x:%02x%02x:%02x%02x:%02x%02x",
			ipaddr[0],
			ipaddr[1],ipaddr[2],ipaddr[3],ipaddr[4],
			ipaddr[5],ipaddr[6],ipaddr[7],ipaddr[8],	
			ipaddr[9],ipaddr[10],ipaddr[11],ipaddr[12],
			ipaddr[13],ipaddr[14],ipaddr[15])

print("ip addr", ipaddrs)
print("node id", storm.os.nodeid())

sport_broadcast = 1611
sport_broadcast_ack = 1612
sport_send = 1622
sport_listen = 1623

sport_send_ping = 1623
sport_listen_ping = 1624

invoke_once = 1

-- create echo server as handler
server_listen_broadcast = function()
   ssock_broadcast = storm.net.udpsocket(sport_broadcast, 
			       function(payload, from, port)
				print("HERE")
                                  local msg = storm.mp.unpack(payload)
                                  if (msg.desc ~= nil and msg.desc == "SERVICE") then
                                     for key,val in pairs(msg) do 
                                        print("key",key,"value",val) 
                                        if (key ~= "id" and key ~= "desc") then
                  			   for i = 1, #val.service_type do
                       				if (val.service_type[i] == "student") then
							service_table[service_count] = {}
							service_table[service_count].from = from
							service_table[service_count].desc = val.desc
						        service_table[service_count].name = key
							service_table[service_count].s = val.s
							service_table[service_count].service_type = "student"
							service_count = service_count + 1
 						end
                                        
						if (val.service_type[i] == "staff") then
							service_table[service_count] = {}
							service_table[service_count].from = from
							service_table[service_count].desc = val.desc
						        service_table[service_count].name = key
							service_table[service_count].s = val.s
							service_table[service_count].service_type = "staff"
							service_count = service_count + 1
 						end
                                        
						if (val.service_type[i] == "prof") then
							service_table[service_count] = {}
							service_table[service_count].from = from
							service_table[service_count].desc = val.desc
						        service_table[service_count].name = key
							service_table[service_count].s = val.s
							service_table[service_count].service_type = "prof"
							service_count = service_count + 1
 						end
                                        
 					   end
                                        end
                                    end
                                    local msg_ack = {}
                                    msg_ack.id = server_id
                                    msg_ack.desc = "ACK"
                                    local payload_ack = storm.mp.pack(msg_ack) 
				    storm.net.sendto(ssock_broadcast, payload_ack, from, sport_broadcast_ack)
				    if (invoke_once == 1) then
				    	User_interface()
					invoke_once = 0
				    end
                                  end
			       end)
end

server_listen_service = function()
	ssock_service = storm.net.udpsocket(sport_listen, 
			       function(payload, from, port)
					print (string.format("from %s port %d: %s",from,port,payload))
					storm.os.cancel(service_invoke)
					local msg = storm.mp.unpack(payload)
					print("Service Data "..msg.payload.." Degree Celsius\n")
					User_interface()
				end)

end

server_listen_broadcast()			-- every node runs the echo server
server_listen_service()

User_interface = function()
cord.new( function()
     print("Are you a Student, a Prof or a Staff ? \n")
     print ("Press 1 if you are a student \n")
     print ("Press 2 if you are a prof \n") 
     print ("Press 3 if you are a staff \n") 

     local option = io.read()
     print("Options"..option)
     local serv_type

     if (option == "1") then
	serv_type = "student"
     elseif (option == "2") then
	serv_type = "prof"
     elseif (option == "3") then
        serv_type = "staff"
     end

     for i = 1, service_count - 1 do
	if (service_table[i].service_type == serv_type) then
		print(i..". "..service_table[i].desc.."\n")
	end
      end
       
     local service_choice_string = io.read()
     local service_choice = tonumber(service_choice_string)
     if (service_table[service_choice].s == "lcdDisp") then
			print("Input message to be displayed: ")
                	local lcd_message = io.read()
                	local service_msg = {}
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {lcd_message}
			local service_msg_payload = storm.mp.pack(service_msg)
                	service_invoke = storm.os.invokePeriodically(1*storm.os.SECOND, function () storm.net.sendto(ssock_service,  							service_msg_payload, service_table[service_choice].from, sport_send) end)    
     elseif  (service_table[service_choice].s == "subscribeToTemp") then
			local service_msg = {}
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {}
			local service_msg_payload = storm.mp.pack(service_msg)
                	service_invoke = storm.os.invokePeriodically(1*storm.os.SECOND, function () storm.net.sendto(ssock_service,  							service_msg_payload, service_table[service_choice].from, sport_send) end)   
    end
  end)
end


cord.enter_loop() -- start event/sleep loop
