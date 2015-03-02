--[[
  Buzzer
 The example use a buzzer to play melodies. It sends a square wave of the 
 appropriate frequency to the buzzer, generating the corresponding tone.
 
 The circuit:
 * Buzzer attached to pin39 (J14 plug on Grove Base BoosterPack)
 * one side pin (either one) to ground
 * the other side pin to VCC
 * LED anode (long leg) attached to RED_LED
 * LED cathode (short leg) attached to ground
 
 * Note:  
 
 
 This example code is in the public domain.
 
 http://www.seeedstudio.com/wiki/index.php?title=GROVE_-_Starter_Kit_v1.1b#Grove_-_Buzzer
 
]]--
require ("cord")
LCD = require "lcd"

lcd = LCD.new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4)

write_to_screen = function(str)
    cord.new(function ()
        lcd.init(2, 1)
        lcd.writeString(str)
    end)
end

storm.io.set_mode(storm.io.OUTPUT, storm.io.D6)
name = { 'c', 'd', 'e', 'f', 'g', 'a', 'b' };
tones = { 1915, 1700, 1519, 1432, 1275, 1136, 1014 };
length = 7
--handle_buzz = 0

function onconnect(state) 
	print("IGNORE")
end


storm.bl.enable("unused", onconnect, function()

   local piano_handle = storm.bl.addservice(0x1337)
   char_handle = storm.bl.addcharacteristic(piano_handle, 0x1338, function(x)
       local buzz = string.sub(x,1,2)
       local note = string.sub(x,4)
       local state = 0
       found_note = -1
       print("INPUT: "..x)
       if(buzz == "on") then
	   for i = 1, length do
		if (note == name[i]) then
		  found_note = i
		end
	   end
	   if (found_note == -1) then
		print("INVALID NOTE: "..note)
		return

	   end
	   print("FOUND IT: name[found_note])")
  	   state = 1
	elseif (buzz == "of") then
	   state = 0
	else
	   print("INVALID MESG: "..x)
	end

	if (state == 1) then
		local i = 0
		while (i < 300*1000) do
			storm.io.set(1,storm.io.D6)
        		for j = 1, tones[found_note]/2  do j = j + 1 end
			storm.io.set(0,storm.io.D6)
			for j = 1, tones[found_note]/2 do j = j + 1 end
			i= i + tones[found_note] * 2
		end
		storm.io.set(0,storm.io.D6)
	end

       
   end)

	local lcd_handle = storm.bl.addservice(0x1339)
	lcd_handle_1 = storm.bl.addcharacteristic(lcd_handle, 0x1340, function(x)
		 write_to_screen(x)
	end)
end)



cord.enter_loop()


