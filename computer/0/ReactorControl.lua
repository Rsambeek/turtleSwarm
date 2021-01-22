local peripherals = peripheral.getNames()

for i=#peripherals,1,-1 do
  if not string.find(peripherals[i], "thermalexpansion:storage_cell") then
    table.remove(peripherals, i)
  end
end

local maxEnergyCells = 0
for i=1,#peripherals do
  peripherals[i] = peripheral.wrap(peripherals[i])
  maxEnergyCells = maxEnergyCells + peripherals[i].getEnergyCapacity()
end


function getEnergyFromCells()
  storedEnergy = 0
  for i=1,#peripherals do
    storedEnergy = storedEnergy + peripherals[i].getEnergyStored()
  end
  return storedEnergy
end

local reactor = peripheral.wrap("back")
local maxEnergy = reactor.getEnergyCapacity() + maxEnergyCells

while true do
    currentEnergy = reactor.getEnergyStored() + getEnergyFromCells()
    
    term.setCursorPos(1,1)
    term.clear()
    print("EnergyStored: " .. currentEnergy .. "RF " .. math.floor((currentEnergy*100)/maxEnergy) .. "%")
    print("Reactor Active: " .. tostring(reactor.getActive()))
        
    if currentEnergy/maxEnergy > 0.8 or reactor.getEnergyStored()/reactor.getEnergyCapacity() > 0.6 then
        reactor.setActive(false)

    elseif currentEnergy/maxEnergy < 0.1 then
        reactor.setActive(true)
        
    end
    
    sleep(1)
end
