local tb = require("/Toolbox")

local floor, exp, max, min, abs, table_insert = math.floor, math.exp, math.max, math.min, math.abs, table.insert

GPSClass = {data={}}

-- GPSClass.modem = nil
GPSClass.position = nil
GPSClass.hasFix = false

function GPSClass.trilaterate( A, B, C )

    A[1] = vector.new(A[1]["x"], A[1]["y"], A[1]["z"])
    B[1] = vector.new(B[1]["x"], B[1]["y"], B[1]["z"])
    C[1] = vector.new(C[1]["x"], C[1]["y"], C[1]["z"])
    local a2b = B[1] - A[1]
    local a2c = C[1] - A[1]

    if math.abs( a2b:normalize():dot( a2c:normalize() ) ) > 0.999 then
        return nil
    end

    local d = a2b:length()
    local ex = a2b:normalize( )
    local i = ex:dot( a2c )
    local ey = (a2c - (ex * i)):normalize()
    local j = ey:dot( a2c )
    local ez = ex:cross( ey )

    local r1 = A[2]
    local r2 = B[2]
    local r3 = C[2]

    local x = (r1*r1 - r2*r2 + d*d) / (2*d)
    local y = (r1*r1 - r3*r3 - x*x + (x-i)*(x-i) + j*j) / (2*j)

    local result = A[1] + (ex * x) + (ey * y)

    local zSquared = r1*r1 - x*x - y*y
    if zSquared > 0 then
        local z = math.sqrt( zSquared )
        local result1 = result + (ez * z)
        local result2 = result - (ez * z)

        local rounded1, rounded2 = result1:round( 0.01 ), result2:round( 0.01 )
        if rounded1.x ~= rounded2.x or rounded1.y ~= rounded2.y or rounded1.z ~= rounded2.z then
            return rounded1, rounded2
        else
            return rounded1
        end
    end
    return result:round( 0.01 )
end

function GPSClass.narrow( p1, p2, fix )
    local dist1 = math.abs( (p1 - fix[1]):length() - fix[2] )
    local dist2 = math.abs( (p2 - fix[1]):length() - fix[2] )

    if math.abs(dist1 - dist2) < 0.01 then
        return p1, p2
    elseif dist1 < dist2 then
        return p1:round( 0.01 )
    else
        return p2:round( 0.01 )
    end
end

function GPSClass.locate()
  responses = GPSClass.requestSatellites(1)
  if responses ~= nil and #responses >= 4 then
    local i=3
    local pos1, pos2
    while true do
      if not pos1 then
        pos1, pos2 = GPSClass.trilaterate(responses[1], responses[2], responses[i])
      else
        pos1, pos2 = GPSClass.narrow(pos1, pos2, {responses[i][1],responses[i][2]})
      end
      i=i+1
      if (pos1 and not pos2) or (i > #responses) then
        break
      end
    end

    if pos1 and not pos2 then
      --print("Position found! : " .. pos1.x .. "," .. pos1.y .. "," .. pos1.z)
      GPSClass.position = pos1
      GPSClass.hasFix = true
      return true, #responses
    end

  -- Only accesible no GPS is available
  end
  --print("Unable to determine position")
  GPSClass.hasFix = false
  return false
end

function GPSClass.requestSatellites(timerTime)
  modem.open(os.getComputerID())
  local id = os.startTimer(timerTime)
  local responses = {}
  modem.transmit(tb.phoneBook["positionChannel"], os.getComputerID(), "ping")
  while true do
    local event = { os.pullEvent() }
    if event[1] == "modem_message" and event[3] == os.getComputerID() then
      responses[#responses + 1] = {event[5], event[6]}

    elseif event[1] == "timer" and event[2] == id then
      break
    end
  end
  modem.close(os.getComputerID())
  return responses
end

function GPSClass.getPosition()
  return GPSClass.position
end

function GPSClass.calibrate()
  GPSClass.locate()
  --print("Current position: " .. myGps.position.x .. "," .. myGps.position.y .. "," .. myGps.position.z)
  sleep(0.1)
  return GPSClass.getPosition()
end

function GPSClass.work()
  while true do
    modem.open(tb.phoneBook["positionChannel"])
    local event = { os.pullEvent() }
    if event[1] == "modem_message" and event[3] == tb.phoneBook["positionChannel"] and event[4] ~= os.getComputerID() and event[5] == "ping" then
      if GPSClass.hasFix then
        modem.transmit(event[4], tb.phoneBook["positionChannel"], GPSClass.position)
      end
    end
  end

  modem.close(tb.phoneBook["positionChannel"])
end

function GPSClass.changePosition(movementVector)
  if GPSClass.position ~= nil then
    GPSClass.position = GPSClass.position + movementVector
    return true
  else
    return false
  end
end

return {GPSClass = GPSClass}
