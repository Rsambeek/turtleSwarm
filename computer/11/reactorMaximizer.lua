reactor = peripheral.wrap("back")
gate = peripheral.wrap("flux_gate_0")
gate2 = peripheral.wrap("flux_gate_1")

repeat
  term.clear()
  term.setCursorPos(1,1)
  print("Maximizing reactor")
  reactorInfo = reactor.getReactorInfo()
  print("Generation at " .. reactorInfo["generationRate"] .. "RF")
  
  if reactorInfo["energySaturation"] > 100000000 then
    if reactorInfo["temperature"] < 8500 then
      gate.setSignalHighFlow(reactorInfo["generationRate"])
--      print("Succes")
    else
      gate.setSignalHighFlow(gate.getSignalHighFlow() - 1)
    end
  end

  if reactorInfo["fieldStrength"] < 10000000 then
    gate2.setSignalHighFlow(gate2.getSignalHighFlow() * 1.2)
  elseif reactorInfo["fieldStrength"] > 45000000 then
    gate2.setSignalHighFlow(gate2.getSignalHighFlow() / 1.002)
  elseif reactorInfo["fieldStrength"] < 40000000 then
    gate2.setSignalHighFlow(gate2.getSignalHighFlow() * 1.01)
  end
--  print(textutils.serialize(reactorInfo))
  sleep(1)
until gate.getSignalHighFlow() > 4000000
