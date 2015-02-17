--[[
   echo client as server
   currently set up so you should start one or another functionality at the
   stormshell
--]]

require "cord" -- scheduler / fiber library

print("\n\n\t\tMaster Server Test\n\n")

local service_table = {}

local service_count = 1

sport_broadcast = 1611
sport_broadcast_ack = 1612
sport_send = 1622
sport_listen = 1623
sport_send_ping = 1623
sport_listen_ping = 1624

invoke_once = 1

local previous = {}

-- create echo server as handler
server_listen_broadcast = function()
   ssock_broadcast = storm.net.udpsocket(sport_broadcast, 
			       function(payload, from, port)
				print("HERE")
				local msg = storm.mp.unpack(payload)
                                  if (msg.desc ~= nil and msg.desc == "SERVICE") then
                                     for key,val in pairs(msg) do 
                                        print("key",key,"value",val) 
					if (previous[from] ~= nil) then
						if (key == previous[from].name) then
							local msg_ack = {}
                                    			msg_ack.id = server_id
				    			msg_ack.name = service_table[service_count-1].name
                                    			msg_ack.desc = "ACK"

                                    			local payload_ack = storm.mp.pack(msg_ack) 
				    			storm.net.sendto(ssock_broadcast, payload_ack, from, sport_broadcast_ack)
							return 
						end
					end
                                        if (key ~= "id" and key ~= "desc") then
                  			   for i = 1, #val.service_type do
						service_table[service_count] = {}
						service_table[service_count].from = from
						service_table[service_count].desc = val.desc
						service_table[service_count].name = key
						service_table[service_count].s = val.s
                       				if (val.service_type[i] == "student") then
							service_table[service_count].service_type = "student"
						elseif (val.service_type[i] == "staff") then
							service_table[service_count].service_type = "staff"
						elseif (val.service_type[i] == "prof") then
							service_table[service_count].service_type = "prof"
 						end
						service_count = service_count + 1
 					   end
                                        end
                                    end
                                    local msg_ack = {}
                                    msg_ack.id = server_id
				    msg_ack.name = service_table[service_count-1].name
                                    msg_ack.desc = "ACK"

                                    local payload_ack = storm.mp.pack(msg_ack) 
				    storm.net.sendto(ssock_broadcast, payload_ack, from, sport_broadcast_ack)

				    if (invoke_once == 1) then
				    	
						User_interface()
					
					invoke_once = 0
				    end
				    previous[from] = {}
				    previous[from].name = service_table[service_count-1].name
                                  end
			       end)
end

server_listen_service = function()
   cord.new(function()
	ssock_service = storm.net.udpsocket(sport_listen, 
			       function(payload, from, port)
					print (string.format("from %s port %d: %s",from,port,payload))
					storm.os.cancel(service_invoke)
					local msg = storm.mp.unpack(payload)
					print("Service Data: "..msg.payload.."\n")
					
						User_interface()
					
				end)
	end)
end

server_listen_broadcast()			-- every node runs the echo server
server_listen_service()

interface = 0

User_interface = function()
cord.new( function()
while (interface == 0) do
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

     local available_choices = {}
     local available_choice_index = 1

     for i = 1, service_count - 1 do
	if (service_table[i].service_type == serv_type) then
		print(i..". "..service_table[i].desc.."\n")
		available_choices[available_choice_index] = i
		available_choice_index = available_choice_index + 1
	end
     end
       
     local service_choice_string = io.read()
     local service_choice = tonumber(service_choice_string)
     
     local service_msg = {}
     if (service_table[service_choice].s == "lcdDisp") then
			print("Input message to be displayed: ")
                	local lcd_message = io.read()
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {lcd_message}   
    elseif  (service_table[service_choice].s == "subscribeToTemp") then
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {}
    elseif (service_table[service_choice].s == "setLed") then
			print("Turn Light on/off (1/0)? ")
                	local light = io.read()
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {tonumber(light)}   
    elseif (service_table[service_choice].s == "setBuzzer") then
			print("Turn Buzzer on/off (1/0)? ")
                	local buzz = io.read()
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {tonumber(buzz)}   
   elseif (service_table[service_choice].s == "setRelay") then
			print("Turn Buzzer on/off (1/0)? ")
                	local relay = io.read()
     			service_msg.name = service_table[service_choice].name
			service_msg.args = {tonumber(relay)}   
    end
    local service_msg_payload = storm.mp.pack(service_msg)
    service_invoke = storm.os.invokePeriodically(7*storm.os.SECOND, function () storm.net.sendto(ssock_service,  							service_msg_payload, service_table[service_choice].from, sport_send) end) 

    interface = 1
    end
    interface = 0
  end)
end


cord.enter_loop() -- start event/sleep loop
