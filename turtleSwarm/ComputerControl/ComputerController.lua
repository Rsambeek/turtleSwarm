local tb = require("/turtleSwarm/Toolbox")
local gps = require("/turtleSwarm/ComputerControl/GPS/src/GPSClass")

-- Instanciate dependencies
modem = peripheral.wrap("right")
myGps = gps.GPSClass

local deviceTypes = {["satellite"] = true,
                     ["pc"] = true,
                     ["server"] = true,
                     ["turtle"] = true}

-- Functions
function startGps(deviceType)
  -- Set GPS type per device type
  local gpsType = nil
  if deviceType == "satellite" then
    gpsType = "static"
  elseif deviceType == "turtle" or deviceType == "pc" then
    gpsType = "dynamic"
  end

  local gpsControl = multishell.launch({require = require, tb = tb, myGps = myGps, modem = modem}, "/turtleSwarm/ComputerControl/GPS/GPSController.lua", gpsType)
  multishell.setTitle(gpsControl, "GPS Controller")

  repeat
    sleep(1)
  until myGps.hasFix
  print("GPS Ready")
  print()
end


-- Main Code
term.clear()
term.setCursorPos(1,1)

if os.getComputerLabel() == nil or #os.getComputerLabel() < 2 then
  local input
  repeat
    input = tb.inputValue("What is my name Overlord?\n")
  until #input >= 2
  os.setComputerLabel(input)

  print("Thank you Overlord")
  print("From now on I will be named " .. input)
  sleep(2)
end

print(os.getComputerLabel() .. " at your service")
sleep(2)

local previousSettings = tb.getSettingFile("deviceSettings")
if previousSettings[1] then
  deviceSettings = previousSettings[2]
else
  term.clear()
  repeat
    print("What am I?")
    deviceType = read()
    term.clear()
  until deviceTypes[deviceType]

  deviceSettings = {deviceType = deviceType}
  tb.setSettingFile("deviceSettings", deviceSettings)
end

term.clear()
term.setCursorPos(1,1)


if deviceSettings["deviceType"] == "satellite" then
  print("Satellite Activated")
  startGps("satellite")
  print(os.getComputerLabel() .. " is supporting the swarm")

elseif deviceSettings["deviceType"] == "server" then
  print("Server node Activated")
  startGps("pc")

  local ServerController = require("/turtleSwarm/ComputerControl/ServerController")
  serverController = ServerController.ServerController

  print("Server API Loaded")

  serverController.start()

elseif deviceSettings["deviceType"] == "pc" then
  print("PC node Activated")
  startGps("pc")

elseif deviceSettings["deviceType"] == "turtle" then
  print("Turtle Worker Activated")
  startGps("turtle")

  local SmartTurtle = require("/turtleSwarm/ComputerControl/SmartTurtle")
  smartTurtle = SmartTurtle.SmartTurtle
  
  print("Turtle API Loaded")

  smartTurtle.start(turtle, myGps, "manual")
end
