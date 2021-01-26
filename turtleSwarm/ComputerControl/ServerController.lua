local tb = require("/Toolbox")
local as = require("/arrayStorage/ArrayStorage")

ServerController = {data={}}

function ServerController.mapDatabase()
  local map = {}
  local arrayStorage = as.ArrayStorage
  arrayStorage.syncArray()
  local previousSettings = tb.getSettingFile("mapDB")
  if previousSettings[1] then
    map = previousSettings[2]
  end

  local function mapController()
    while true do
      modem.open(tb.phoneBook["mapChannel"])
      local event = { os.pullEvent() }
      if event[1] == "modem_message" and event[3] == tb.phoneBook["mapChannel"] then
        if event[5][1] == "updateMap" then
          local request = {}
          turtlePosition = event[5][2]
          for index, block in pairs(event[5][3]) do
            if block.name ~= "minecraft:air" then
              block.x = block.x + turtlePosition.x
              block.y = block.y + turtlePosition.y
              block.z = block.z + turtlePosition.z
              request[textutils.serialize(vector.new(block.x, block.y, block.z))] = textutils.serialize(block)
            end
            if (index % 30 == 0) then sleep(0) end
          end
          arrayStorage.writeValues(request)
          --tb.setSettingFile("mapDB", map)
        elseif event[5][1] == "readMap" then
          print("request received")
          local startVector = event[5][2]
          local endVector = event[5][3]
          local request = {}
          local blocks = {}
          local indexVector = vector.new()
          for i=startVector.x,endVector.x do
            indexVector.x = i
            for j=startVector.y,endVector.y do
              indexVector.y = j
              for k=startVector.z,endVector.z do
                indexVector.z = k
                list.insert(request,indexVector)
                if ((((i-1)*endVector.y) + ((j-1)*endVector.z) + k) % 100 == 0) then sleep(0) end
              end
            end
          end
          blocks = arrayStorage.readValues(request)
          sleep(1)
          print("Data Send")
          modem.transmit(event[4], tb.phoneBook["mapChannel"], blocks)
        end
      end
      modem.close(tb.phoneBook["mapChannel"])
    end
  end

  local function debugMapPrinter()
    while true do
      local command = tb.inputValue("Command")
      if command == "dump" then
        --print(textutils.serialize(map))
        print("Command not supported")
      elseif command == "getBlock" then
        local x = tb.inputValue("X")
        local y = tb.inputValue("Y")
        local z = tb.inputValue("Z")
        targetBlock = arrayStorage.readValue(textutils.serialize(vector.new(x, y, z)))
        if targetBlock ~= nil then
          print(textutils.unserialize(targetBlock).name)
        else
          print("Target Block: nil or air")
        end
      end
    end
  end

  parallel.waitForAny(mapController, debugMapPrinter)
end

function ServerController.start()
  -- serverType = tb.inputValue("Server type")
  serverType = "mapServer"
  if serverType == "mapServer" then
    ServerController.mapDatabase()
  end
end

return {ServerController = ServerController}