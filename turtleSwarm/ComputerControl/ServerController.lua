local tb = require("/Toolbox")

ServerController = {data={}}

function ServerController.mapDatabase()
  local map = {}
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
          turtlePosition = event[5][2]
          for index, block in pairs(event[5][3]) do
            if block.name ~= "minecraft:air" then
              block.x = block.x + turtlePosition.x
              block.y = block.y + turtlePosition.y
              block.z = block.z + turtlePosition.z
              map[textutils.serialize(vector.new(block.x, block.y, block.z))] = textutils.serialize(block)
              -- map[vector.new(block.x, block.y, block.z)] = textutils.serialize(block)
            end
            if (index % 30 == 0) then sleep(0.05) end
          end
          tb.setSettingFile("mapDB", map)
        elseif event[5][1] == "readMap" then
          print("request received")
          local startVector = event[5][2]
          local endVector = event[5][3]
          local blocks = {}
          local indexVector = vector.new()
          for i=startVector.x,endVector.x do
            indexVector.x = i
            for j=startVector.y,endVector.y do
              indexVector.y = j
              for k=startVector.z,endVector.z do
                indexVector.z = k
                if map[textutils.serialize(indexVector)] ~= nil then
                  blocks[textutils.serialize(indexVector)] = textutils.unserialize(map[textutils.serialize(indexVector)])
                else
                  blocks[textutils.serialize(indexVector)] = "nil"
                end
                if ((((i-1)*endVector.y) + ((j-1)*endVector.z) + k) % 100 == 0) then sleep(0) end
              end
            end
          end
          sleep(0.1)
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
        print(textutils.serialize(map))
      elseif command == "getBlock" then
        local x = tb.inputValue("X")
        local y = tb.inputValue("Y")
        local z = tb.inputValue("Z")
      end
        targetBlock = map[textutils.serialize(vector.new(x, y, z))]
      if targetBlock ~= nil then
        print(textutils.unserialize(targetBlock).name)
      else
        print("Target Block: nil or air")
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