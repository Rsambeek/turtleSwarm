-- pastebin get RZGxa897 setupSwarmAPI.lua
fs.delete("turtleSwarm/")
if not fs.exists("gitget") then
    shell.run("pastebin get W5ZkVYSi gitget")
end
shell.run("gitget Rsambeek turtleSwarm development")