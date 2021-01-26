local tb = require("/Toolbox")

ArrayStorage = {data={}}

ArrayStorage.drives = {peripheral.find("drive")}
ArrayStorage.fillingDrive = "disk/file"
ArrayStorage.dictionary = {}

function ArrayStorage.syncArray()
    print("Syncing Array")
    for i=1,#ArrayStorage.drives do
        driveName = "disk"
        if i ~= 1 then
            driveName = (driveName .. i)
        end
        driveName = ("/" .. driveName .. "/file")
        ArrayStorage.drives[i] = driveName
        if fs.exists(driveName) then
            ArrayStorage.fillingDrive = (driveName)
            file = fs.open(driveName, "r")
            temp = textutils.unserialize(file.readAll())
            file.close()

            for k,_ in pairs(temp) do
                ArrayStorage.dictionary[k] = (driveName)
            end
        end
    end
end

function ArrayStorage.setFillingDrive()
    if fs.getFreeSpace(ArrayStorage.fillingDrive) < 1000 then
        for i=1,#ArrayStorage.drives do
            if ArrayStorage.drives[i] == ArrayStorage.fillingDrive then
                if i == #drives then
                    print("Storage Array Full")
                    return false
                else
                    ArrayStorage.fillingDrive = ArrayStorage.drives[i+1]
                end
            end
        end
    end
end

function ArrayStorage.readValue(key)
    local output
    if ArrayStorage.dictionary[key] ~= nil then
        file = fs.open(ArrayStorage.dictionary[key], "r")
        output = textutils.unserialize(file.readAll())[key]
        file.close()
    end
    return output
end

function ArrayStorage.readValues(keys)
    local loadedDrives = {}
    local output = {}
    for i=1,#ArrayStorage.drives do
        if fs.exists(ArrayStorage.drives[i]) then
            file = fs.open(ArrayStorage.drives[i], "r")
            loadedDrives[i] = textutils.unserialize(file.readAll())
            file.close()
        end
    end
    for i=1,#keys do
        output[keys[i]] = loadedDrives[ArrayStorage.dictionary[keys[i]]][keys[i]]
        if i%20 == 0 then sleep(0) end
    end

    return output
end

function ArrayStorage.writeValue(key, data)
    if ArrayStorage.dictionary[key] == nil then
        ArrayStorage.setFillingDrive()
        ArrayStorage.dictionary[key] = ArrayStorage.fillingDrive
    end
    local fileData = {}
    if fs.exists(ArrayStorage.dictionary[key]) then
        file = fs.open(ArrayStorage.dictionary[key], "r")
        fileData = textutils.unserialize(file.readAll())
        file.close()
    end
    print(textutils.serialize(fileData))
    fileData[key] = data

    file = fs.open(ArrayStorage.dictionary[key], "w")
    file.write(textutils.serialize(fileData))
    file.close()
end

function ArrayStorage.writeValues(data)
    local newEntries = {}
    local loadedDrives = {}
    for i=1,#ArrayStorage.drives do
        if fs.exists(ArrayStorage.drives[i]) then
            file = fs.open(ArrayStorage.drives[i], "r")
            loadedDrives[i] = textutils.unserialize(file.readAll())
            file.close()
        end
        sleep(0)
    end
    print("loaded Drives")

    for key,value in pairs(data) do
        sleep(0)
        if ArrayStorage.dictionary[key] == nil then
            newEntries[key] = value
        else
            loadedDrives[ArrayStorage.dictionary[key]][key] = value
        end
    end
    print("Filtered Data")
    for i=1,#ArrayStorage.drives do
        if loadedDrives[i] ~= nil then
            file = fs.open(ArrayStorage.drives[i], "w")
            file.write(textutils.serialize(loadedDrives[i]))
            file.close()
        end
        sleep(0)
    end
    print("Updated Data")

    for key,value in pairs(newEntries) do
        ArrayStorage.writeValue(key,value)
        sleep(0)
    end
    print("Stored New Data")
end

return {ArrayStorage = ArrayStorage}