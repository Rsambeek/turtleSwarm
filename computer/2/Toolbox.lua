local phoneBook = {["communicationChannel"] = 0,
                   ["positionChannel"] = 1,
                   ["mapChannel"] = 2}

local function inputValue(printText)
  if printText ~= nil then
    term.write(printText .. ": ")
  end
  return read()
end

local function tableToVector(inputTable)
  if inputTable.x ~= nil then
    return vector.new(inputTable.x, inputTable.y, inputTable.z)
  elseif inputTable[1] ~= nil then
    return vector.new(inputTable[1], inputTable[2], inputTable[3])
  else
    return false
  end
end

local function busSimpleCommunicate(target, source, data, waitResponse)
  os.queueEvent(target, source, data)
  if waitResponse then
    while true do
      local event = { os.pullEvent() }
      --if event[1] ~= "timer" then print(event[3]) end
      if event[1] == source and event[2] == target then
        return textutils.unserialize(event[3])
      end
    end
  end
end

local function busLongCommunicate(target, source, message, data, waitResponse)
  os.queueEvent(target, source, message, data)
  if waitResponse ~= nil and waitResponse then
    while true do
      local event = { os.pullEvent() }
      if event[1] == source and event[2] == target then
        return event[3]
      end
    end
  end
end

local function getSettingFile(fileName)
  returnValue = {false}
  if fs.exists("/settings/" .. fileName) then
    settings = fs.open("/settings/" .. fileName, "r")
    returnValue =  {true, textutils.unserialize(settings.readAll())}
    settings.close()
  end
  return returnValue
end

local function setSettingFile(fileName, data)
  settings = fs.open("/settings/" .. fileName, "w")
  settings.write(textutils.serialize(data))
  settings.close()
end

local function loadFromStorageArray(diskDrives)
  returnValue = {false}
  if fs.exists("/disk/" .. "file") then
    settings = fs.open("/disk/" .. fileName, "r")
    returnValue =  textutils.unserialize(settings.readAll())
    settings.close()
  else 
    return false
  end
  return returnValue
end

local function loadToStorageArray(diskDrives, data)
end

return {phoneBook = phoneBook,
        inputValue = inputValue,
        tableToVector = tableToVector,
        busSimpleCommunicate = busSimpleCommunicate,
        busLongCommunicate = busLongCommunicate,
        getSettingFile = getSettingFile,
        setSettingFile = setSettingFile}
