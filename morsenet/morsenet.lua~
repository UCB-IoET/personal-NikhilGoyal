require("cord")
require("storm")
shield = require("starter") -- interfaces for resources on starter shield
morse = require("morse") -- interfaces for resources on starter shield
LED = require("led")

local morse_code = {}
local num_code = 0
local press_threshold = 40000
local start_time = 0
local end_time = 0
local got_something = 0

local first_edge = 0
blu = LED:new("D2")		
grn = LED:new("D3")
red = LED:new("D4")

ipaddr = storm.os.getipaddr()
ipaddrs = string.format("%02x%02x:%02x%02x:%02x%02x:%02x%02x::%02x%02x:%02x%02x:%02x%02x:%02x%02x",
			ipaddr[0],
			ipaddr[1],ipaddr[2],ipaddr[3],ipaddr[4],
			ipaddr[5],ipaddr[6],ipaddr[7],ipaddr[8],	
			ipaddr[9],ipaddr[10],ipaddr[11],ipaddr[12],
			ipaddr[13],ipaddr[14],ipaddr[15])

print("ip addr", ipaddrs)
print("node id", storm.os.nodeid())
cport = 50001

-- create client socket
csock = storm.net.udpsocket(cport, 
			    function(payload, from, port)
                               print("Received something")
			       red:flash(3)
			       print (string.format("echo from %s port %d: %s",from,port,payload))
                               got_something = 1
			    end)

client = function(letter)
  cord.new(function()
   blu:flash(1)
   while (got_something == 0) do
       print("send: "..letter)
       storm.net.sendto(csock, letter, "::1", cport) 
       local count = 0
       cord.await(storm.os.invokeLater, 1*storm.os.SECOND)
   end
   grn:flash(1)
   end)
end


print("Begin Morse Coding")

shield.Button.start()
morse.computeMorseToAlpha()
                                
shield.Button.whenever_gap(3, "CHANGE", function()
                               if (first_edge == 0) then
                                 print("F")
				 start_time = storm.os.now(storm.os.SHIFT_0)
                                 num_code = num_code + 1
                                 print("FALLING: "..start_time)
                                 first_edge = 1
                               else
                                 print("R")
                                 end_time = storm.os.now(storm.os.SHIFT_0)
                                 press_time = end_time - start_time
                                 print("RISING: "..end_time)
                                 if (press_time > press_threshold) then
                                    morse_code[num_code] = true
                                 else
                                    morse_code[num_code] = false
                                 end
                                  first_edge = 0
                               end
				end)

shield.Button.whenever_gap(2, "FALLING", function()
				local curr_table = morse.MorseToAlpha
                                for i = 1, num_code do
                                    curr_table = curr_table[morse_code[i]]
                                end
                                local letter = curr_table['end']
                                num_code = 0
                                print("LETTER: "..letter)
                                client(letter)
                                end)

cord.enter_loop()
