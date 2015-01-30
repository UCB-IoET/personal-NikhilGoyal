require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
shield = require("starter") -- interfaces for resources on starter 

shield.LED.start()
-- set buttons as inputs
storm.io.set_mode(storm.io.INPUT,   storm.io.D9, storm.io.D10, storm.io.D11)
-- enable internal resistor pullups (none on board)
storm.io.set_pull(storm.io.PULL_UP, storm.io.D9, storm.io.D10, storm.io.D11)
storm.io.set_mode(storm.io.OUTPUT, storm.io.D6)



local num = 0

displayLED = function()
    num = math.random(0,2)    
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

checkButtonNine = function()
    if num ~= 0 then
        storm.io.set(1, storm.io.D6)
        shield.LED.on("red")
        shield.LED.on("blue")
        shield.LED.on("green")
        storm.os.invokeLater(3*storm.os.SECOND, function()
            storm.io.set(0, storm.io.D6) 
            shield.LED.off("red")
            shield.LED.off("blue")
            shield.LED.off("green")
            storm.os.cancel(handleperiodic)
            end)
        return 1
     else then
        return 0
    end
end

checkButtonTen = function()
    if num ~= 1 then
        storm.io.set(1, storm.io.D6)
        shield.LED.on("red")
        shield.LED.on("blue")
        shield.LED.on("green")
        storm.os.invokeLater(3*storm.os.SECOND, function()
            storm.io.set(0, storm.io.D6)
            shield.LED.off("red")
            shield.LED.off("blue")
            shield.LED.off("green")
            end)
    end
end

checkButtonEleven = function()
    if num ~= 2 then
        storm.io.set(1, storm.io.D6)
        shield.LED.on("red")
        shield.LED.on("blue")
        shield.LED.on("green")
        storm.os.invokeLater(3*storm.os.SECOND, function()
            storm.io.set(0, storm.io.D6)
            shield.LED.off("red")
            shield.LED.off("blue")
            shield.LED.off("green") end)
    end
end

handleperiodic = storm.os.invokePeriodically(1*storm.os.SECOND, displayLED)
	
handleTen = storm.io.watch_all(storm.io.FALLING, storm.io.D10, function() 
                                   checkButtonTen()
                                    storm.os.cancel)
handleNine = storm.io.watch_all(storm.io.FALLING, storm.io.D9, checkButtonNine)
handleEleven = storm.io.watch_all(storm.io.FALLING, storm.io.D11, checkButtonEleven)


cord.enter_loop()
