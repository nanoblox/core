--[[

This allows for really easy communication between Client and Server

Simply move ClientRemote to the client and ServerRemote to the server

Server and Client remotes are connected through passing the same name

Example
On the server:
```lua
local tacoRemote = ServerRemote.new("RainTacos")
tacoRemote.onServerInvoke:Connect(function(player)
    local playerHasPermissionToRainTacos = math.random(1,2) == 1
    if playerHasPermissionToRainTacos then
        print("Rain tacos!")
        return false
    end
    return true
end)
```

On the client:
```lua
local tacoRemote = ClientRemote.new("RainTacos")
local success = tacoRemote:invokeServer("RainRacos")
if success then
    print("It rained tacos yay!")
end
```

--]]