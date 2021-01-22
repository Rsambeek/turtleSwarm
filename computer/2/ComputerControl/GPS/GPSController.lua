local arg1 = ...

gpsType = arg1

function start()
  -- Wrap and activate peripherals
  -- myGps.modem = modem
  rednet.open("right")

  -- GPS Position initialisation
  if gpsType == "static" then
    local previousSettings = tb.getSettingFile("gpsCoords")
    if previousSettings[1] then
      myGps.position = previousSettings[2]
      myGps.hasFix = true
    else
      myGps.position = vector.new(tb.inputValue("X"), tb.inputValue("Y"), tb.inputValue("Z"))
      myGps.hasFix = true
      tb.setSettingFile("gpsCoords", myGps.position)
    end

  elseif gpsType == "dynamic" then
    local fix, satellites = myGps.locate()
    if not fix then
      print("Unable to get fix")
      return false
    end

    term.clear()
    term.setCursorPos(1,1)
    print("GPS Setup complete")
    print("Current position: " .. myGps.position.x .. "," .. myGps.position.y .. "," .. myGps.position.z)
  end
  return true
end

function factualizeGPS()
  while true do
    local id = os.startTimer(30)
    while true do
      local event = {os.pullEvent("timer")}
      if event[2] == id then
        myGps.locate()
        break
      end
    end
  end
end

function displayGPS()
  local oldData = {oldPosition = myGps.position, hasFix = myGps.hasFix}

  term.setCursorPos(1,2)
  term.clearLine()
  print("Current position: " .. myGps.position.x .. "," .. myGps.position.y .. "," .. myGps.position.z)

  term.setCursorPos(1,3)
  term.clearLine()
  if not myGps.hasFix then print("Unable to get fix") end

  while true do
    term.setCursorPos(1,2)
    term.clearLine()
    term.write("Current position: ")
    if myGps.hasFix then
    term.write(myGps.position.x .. "," .. myGps.position.y .. "," .. myGps.position.z)
    end

    term.setCursorPos(1,3)
    term.clearLine()
    if not myGps.hasFix then
      print("Unable to get fix")
    end

    sleep(1)
  end
end


while not start() do
  local id = os.startTimer(10)
  while true do
    local event = {os.pullEvent("timer")}
    if event[2] == id then
      break
    end
  end
end

-- GPS meshing
if gpsType == "static" then
  parallel.waitForAny(myGps.work, displayGPS)
elseif gpsType == "dynamic" then
  parallel.waitForAny(myGps.work, displayGPS, factualizeGPS)
end
