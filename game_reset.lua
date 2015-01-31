require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
shield = require("starter") -- interfaces for resources on starter 

shield.LED.start()
-- set buttons as inputs
storm.io.set_mode(storm.io.INPUT,   storm.io.D9, storm.io.D10, storm.io.D11)
-- enable internal resistor pullups (none on board)
storm.io.set_pull(storm.io.PULL_UP, storm.io.D9, storm.io.D10, storm.io.D11)
storm.io.set_mode(storm.io.OUTPUT, storm.io.D6)


--print("local")
local num = 0
local score = 0
local cancel = 0
local start_time = storm.os.now(storm.os.SHIFT_0)
local handleperiodic
local buttonNinePressed = false
local buttonTenPressed  = false
local buttonElevenPressed = false


local blue = true
local green = true
local red = true

checkAndSwitchLED = function()
    print(num)
    print(blue)
    if num == 0 then
        if blue == false then
            loseGame()
        end
    elseif num == 1 then
        if green == false then
            loseGame()
        end
    elseif num == 2 then
        if red == false then
            loseGame()
        end
    end
    resetBools()
    displayLED()   

end

loseGame = function()
-- storm.io.set(1, storm.io.D6)
        local end_time = storm.os.now(storm.os.SHIFT_0)
        shield.LED.on("red")
        shield.LED.on("blue")
        shield.LED.on("green")
        storm.os.invokeLater(3*storm.os.SECOND, function()
            storm.io.set(0, storm.io.D6) 
            shield.LED.off("red")
            shield.LED.off("blue")
            shield.LED.off("green")
            end)
    storm.os.cancel(handleperiodic)
    cancel = 1
    print("YOU LOSE")
    print("YOUR SCORE: "..score)
    local player_time = (end_time - start_time)/storm.os.SECOND
    print("TIME: "..player_time)
    start_time = storm.os.now(storm.os.SHIFT_0)
    score = 0
  
    print("RESET GAME  (0 = no/1 = yes): ")
    local reset = io.read()
    if (reset == "1") then

        shield.LED.off("red")
        shield.LED.off("blue")
        shield.LED.off("green")
	num = 0        
	storm.os.invokeLater(storm.os.SECOND*1, function()
        	handleperiodic = storm.os.invokePeriodically(500*storm.os.MILLISECOND, checkAndSwitchLED)
        	cancel = 0
	end)
    end
end


displayLED = function()
    num = (num + math.random(1,2)) % 3    
    shield.LED.off("blue")
    shield.LED.off("red")
    shield.LED.off("green")
    if num == 0 then
        shield.LED.on("blue")
    end
    if num == 1 then
        shield.LED.on("green")
    end
    if num == 2 then
        shield.LED.on("red")
    end
end


resetBools = function()
    blue = false;
    green = false;
    red = false
end

checkButtonNine = function()
    if (cancel == 0) then
    if num ~= 0 then
        loseGame()
     else
        blue = true
        score = score + 1
        print("Your Score: " .. score)
    end
    end
end

checkButtonTen = function()
    if (cancel == 0) then
    if num ~= 1 then
        loseGame()
       else
        green = true
        score = score + 1
        print("Your Score: " .. score)
    end
   end
end

checkButtonEleven = function()
    if (cancel == 0) then
    if num ~= 2 then
        loseGame()
    else
        red = true
        score = score + 1
        print("Your Score: " .. score)
    end
    end
end

handleperiodic = storm.os.invokePeriodically(500*storm.os.MILLISECOND, checkAndSwitchLED)

handleNine = storm.io.watch_all(storm.io.FALLING, storm.io.D9, function()
                           if (buttonNinePressed == false) then
                              buttonNinePressed = true
			      checkButtonNine()
                               
                              -- local start = storm.os.now(storm.os.SHIFT_0)/storm.os.MILLISECOND
                              -- while storm.os.now(storm.os.SHIFT_0)/storm.os.MILLISECOND - start <= 100 do end

                               -- buttonNinePressed = false
                               storm.os.invokeLater(storm.os.MILLISECOND * 500, function() buttonNinePressed = false end)

                           end
                        end)
	
handleTen = storm.io.watch_all(storm.io.FALLING, storm.io.D10, function()
                           if (buttonTenPressed == false) then

                                buttonTenPressed = true
				checkButtonTen()
                               storm.os.invokeLater(storm.os.MILLISECOND * 500, function() buttonTenPressed = false end)

                           end
                        end)

handleEleven = storm.io.watch_all(storm.io.FALLING, storm.io.D11, function()
                           if (buttonElevenPressed == false) then

                                buttonElevenPressed = true
				checkButtonEleven()
                               storm.os.invokeLater(storm.os.MILLISECOND * 500, function() buttonElevenPressed = false end)

                           end
                        end)


cord.enter_loop()

