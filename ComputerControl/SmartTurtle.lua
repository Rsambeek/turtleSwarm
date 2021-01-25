local tb = require("/Toolbox")

SmartTurtle = {data={}}

SmartTurtle.turtle = nil
SmartTurtle.gps = nil

SmartTurtle.moveCounter = 0
SmartTurtle.dataValues = {["rotation"] = 0}

SmartTurtle.directionToMovement = {vector.new(0,0,-1),
                                   vector.new(1,0,0),
                                   vector.new(0,0,1),
                                   vector.new(-1,0,0),
                                   vector.new(0,1,0),
                                   vector.new(0,-1,0)}

SmartTurtle.movementVectorToDirection = {}
for key,value in pairs(SmartTurtle.directionToMovement) do
  SmartTurtle.movementVectorToDirection[textutils.serialize(value)] = key
end

function SmartTurtle.updateSettings()
  tb.setSettingFile("smartTurtlePersistance", SmartTurtle.dataValues)
end

function SmartTurtle.reverseDirection()
  return (SmartTurtle.dataValues.rotation + 1) % 4 + 1
end

function SmartTurtle.calibrateRotation()
  oldPos = myGps.calibrate()

  for i=1,4 do
    if SmartTurtle.turtle.forward() then
      newPos = myGps.calibrate()

      if newPos.z < oldPos.z then
        SmartTurtle.dataValues.rotation = 1
      elseif newPos.z > oldPos.z then
        SmartTurtle.dataValues.rotation = 3
      elseif newPos.x > oldPos.x then
        SmartTurtle.dataValues.rotation = 2
      elseif newPos.x < oldPos.x then
        SmartTurtle.dataValues.rotation = 4
      end
      SmartTurtle.updateSettings()
      break

    else
      SmartTurtle.turtle.turnRight()
    end
  end
end

function SmartTurtle.updateRotation(direction)
  SmartTurtle.dataValues.rotation = (SmartTurtle.dataValues.rotation + direction + 3) % 4 + 1
  SmartTurtle.updateSettings()
end

function SmartTurtle.rotate(direction)
  if direction == "left" then
    direction = -1
  elseif direction == "right" then
    direction = 1
  end

  if direction < 0 then
    for i=1,math.abs(direction) do
      turtle.turnLeft()
    end
  elseif direction > 0 then
    for i=1,direction do
      turtle.turnRight()
    end
  else
    return false
  end

  SmartTurtle.updateRotation(direction)
  return true
end

function SmartTurtle.rotateTowards(movementVector)
  targetRotation = SmartTurtle.movementVectorToDirection[textutils.serialize(movementVector)]
  
  if targetRotation == nil then
    return false
  end

  deltaRotation = targetRotation - SmartTurtle.dataValues.rotation
  if deltaRotation == 0 or targetRotation > 4 then
    return true
  elseif deltaRotation == 3 or deltaRotation == -1 then
    SmartTurtle.rotate(deltaRotation)
  elseif deltaRotation == 2 or deltaRotation == -2 then
    SmartTurtle.rotate(deltaRotation)
  elseif deltaRotation == 1 or deltaRotation == -3 then
    SmartTurtle.rotate(deltaRotation)
  else
    return false
  end
end

function SmartTurtle.move(direction, amount)
  local moveReturn = nil
  local moveFunction
  if amount == nil then
    amount = 1
  end
  if direction == 5 then
    moveFunction = SmartTurtle.turtle.up
  elseif direction == 6 then
    moveFunction = SmartTurtle.turtle.down
  elseif direction == SmartTurtle.dataValues.rotation then
    moveFunction = SmartTurtle.turtle.forward
  elseif direction == SmartTurtle.reverseDirection() then
    moveFunction = SmartTurtle.turtle.back
  end


  for i=1,amount do
    SmartTurtle.moveCounter = SmartTurtle.moveCounter + 1
    moveReturn = { moveFunction() }
    if moveReturn[1] then
      myGps.changePosition(SmartTurtle.directionToMovement[direction])
    else
      return moveReturn
    end
  end
  return moveReturn
end

function SmartTurtle.forward(amount)
  return SmartTurtle.move(SmartTurtle.dataValues.rotation, amount)
end

function SmartTurtle.back(amount)
  return SmartTurtle.move(SmartTurtle.reverseDirection(), amount)
end

function SmartTurtle.up(amount)
  return SmartTurtle.move(5, amount)
end

function SmartTurtle.down(amount)
  return SmartTurtle.move(6, amount)
end

function SmartTurtle.goto(targetPosition)
  local map = {}
  local priorityQueue = {}
  local currentPosition = myGps.getPosition()
  local currentPositionS = textutils.serialize(currentPosition)
  local targetPositionS = textutils.serialize(targetPosition)
  local message = {"readMap",
                   vector.new(math.min(currentPosition.x, targetPosition.x) - 10,
                              math.min(currentPosition.y, targetPosition.y) - 10,
                              math.min(currentPosition.z, targetPosition.z) - 10),
                   vector.new(math.max(currentPosition.x, targetPosition.x) + 10,
                              math.max(currentPosition.y, targetPosition.y) + 10,
                              math.max(currentPosition.z, targetPosition.z) + 10)}
  modem.open(os.getComputerID())
  modem.transmit(tb.phoneBook["mapChannel"], os.getComputerID(), message)
  local event
  repeat
    event = { os.pullEvent() }
    if event[1] == "modem_message" and event[3] == os.getComputerID() then
      -- print(textutils.serialize(event[4]))
    end
  until event[1] == "modem_message" and event[3] == os.getComputerID() and event[4] == tb.phoneBook["mapChannel"]

  print("Received Local Map")

  for keyS,value in pairs(event[5]) do
    local key = textutils.unserialize(keyS)
    key = vector.new(key.x, key.y, key.z)

    local movementVector = (targetPosition - key)
    if value == "nil" then
      value = nil

      map[keyS] = {value,math.huge,movementVector.length(movementVector),nil}
      if keyS == currentPositionS then
        table.insert(priorityQueue,1 , keyS)
        map[keyS][2] = 0
      else
        table.insert(priorityQueue, keyS)
      end
    end
  end

  print("Local Map Processed")
  
  local expendedQueue = {}
  local function sortingRule(a,b)
    local sideA
    local sideB
    if map[a][2] == math.huge then
      sideA = math.huge
    else
      sideA = map[a][2]+map[a][3]
    end
    if map[b][2] == math.huge then
      sideB = math.huge
    else
      sideB = map[b][2]+map[b][3]
    end
    return (sideA < sideB)
    -- return (map[a][2] ~= -1 and map[a][2]+map[a][3] <= map[b][2]+map[b][3])
    -- return (map[a][2]+map[a][3] <= map[b][2]+map[b][3])
  end

  local function insertInOrder(item)
    placedInOrder = false
    for i=2,#priorityQueue do
      if map[item][2] + map[item][3] < map[priorityQueue[i]][2] + map[priorityQueue[i]][3] then
        table.insert(priorityQueue, i, item)
        placedInOrder = true
      end
      if priorityQueue[i] == item then
        if placedInOrder then
          table.remove(priorityQueue, i)
        end
        return
      end
    end
  end

  local currentNode
  local currentNodeU
  local currentWeight
  local index = 0
  while true do
    --print(#priorityQueue)
    --table.sort(priorityQueue, sortingRule)
    print("test")
    currentNode = priorityQueue[1]
    currentNodeU = textutils.unserialize(currentNode)
    currentWeight = map[currentNode][2]
    --for i=1,#priorityQueue do
    --  if map[priorityQueue[i]][2] ~= -1 then
    --  end
    --end
    -- print(temp.x .. "," .. temp.y .. "," .. temp.z .. "|" .. targetPosition.x .. "," .. targetPosition.y .. "," .. targetPosition.z)
    if currentNode == targetPositionS then
      expendedQueue[currentNode] = currentNode
      break
    elseif currentWeight == math.huge then
      print("Target Unreachable")
      return false
    end

    for i=1,6 do
      local neighbourBlock = currentNodeU + SmartTurtle.directionToMovement[i]
      neighbourBlock = textutils.serialize(vector.new(neighbourBlock.x, neighbourBlock.y, neighbourBlock.z))
      if map[neighbourBlock] ~= nil and expendedQueue[neighbourBlock] == nil then
        if map[neighbourBlock][2] == -1 or map[neighbourBlock][2] > (currentWeight + 1) then
          map[neighbourBlock][2] = (currentWeight + 1)
          map[neighbourBlock][4] = currentNode
          insertInOrder(neighbourBlock)
        end
      end
    end
    table.remove(priorityQueue,1)
    expendedQueue[currentNode] = currentNode
    index = index+1
    if index % 10 == 0 then sleep(0) end
  end
  print("Path found")

  local path = {targetPositionS}
  while path[1] ~= currentPositionS do
    --print(path[1])
    table.insert(path, 1, map[path[1]][4])
    if #path % 25 == 0 then
      sleep(0)
      print("check")
    end
  end
  print("Executing movement")
  local path1,path2
  while path[1] ~= targetPositionS do
    path1 = tb.tableToVector(textutils.unserialize(path[1]))
    path2 = tb.tableToVector(textutils.unserialize(path[2]))
    movementVector = path2 - path1
    SmartTurtle.rotateTowards(movementVector)
    SmartTurtle.move(SmartTurtle.movementVectorToDirection[textutils.serialize(movementVector)])
    table.remove(path, 1)
  end
  print("Target Reached")
end

function backgroundProcesses()
  local peripheralType = peripheral.getType("left")
  tool = peripheral.wrap("left")

  while true do
    if peripheralType == nil then
      return true
    elseif peripheralType == "plethora:scanner" then
      if SmartTurtle.moveCounter >= 5 then
        SmartTurtle.moveCounter = 0
        message = {"updateMap",
                  myGps.getPosition(),
                  tool.scan()}
        modem.transmit(tb.phoneBook["mapChannel"], os.getComputerID(), message)
        print("Area Send")
      end
    end
    sleep(1)
  end
end

function SmartTurtle.swarmManaged()
end

function SmartTurtle.manual()
  while true do
    print("Order Turtle")
    input = read()
    if input == "go" then
      SmartTurtle.forward()
    elseif input == "back" then
      SmartTurtle.back()
    elseif input == "up" then
      SmartTurtle.up()
    elseif input == "down" then
      SmartTurtle.down()
    elseif input == "left" then
      SmartTurtle.rotate("left")
    elseif input == "right" then
      SmartTurtle.rotate("right")
    elseif input == "goto" then
      target = vector.new(tb.inputValue("X"),tb.inputValue("Y"),tb.inputValue("Z"))
      -- target = vector.new(198,95,481)
      print(SmartTurtle.goto(target))
    elseif input == "request" then
      local here = myGps.getPosition()
      local offset = vector.new(3,3,3)
      local message = {"readMap", here + offset, here - offset}
      modem.transmit()
    else
      break
    end
  end
end

function SmartTurtle.start(turtleInstance, myGps, turtleMode)
  SmartTurtle.turtle = turtleInstance

  local previousSettings = tb.getSettingFile("smartTurtlePersistance")
  if previousSettings[1] then
    SmartTurtle.dataValues = previousSettings[2]
  else
    print("I will try to move to orient myself")
    sleep(1)
    if SmartTurtle.turtle.getFuelLevel() > 2 then
      SmartTurtle.calibrateRotation()
      SmartTurtle.updateSettings()
    end
  end

  local selectedFunction = nil
  if turtleMode == "auto" then
    selectedFunction = SmartTurtle.swarmManaged
  elseif turtleMode == "manual" then
    selectedFunction = SmartTurtle.manual
  end
  parallel.waitForAny(selectedFunction, backgroundProcesses)
end

return {SmartTurtle = SmartTurtle}
