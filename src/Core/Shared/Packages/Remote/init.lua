--[[

This allows for really easy communication between Client and Server

Simply move ClientRemote to the client and ServerRemote to the server, then define a folder (under CONFIG) in both modules of where you wish to store the remotes

Server and Client remotes are connected through passing the same name

Example
On the server:
```lua
local tacoRemote = main.modules.Remote.new("RainTacos")
tacoRemote.onServerInvoke = function(player, ...)
    local playerHasPermissionToRainTacos = math.random(1,2) == 1
    print("playerHasPermissionToRainTacos = ", playerHasPermissionToRainTacos, ...)
    if playerHasPermissionToRainTacos then
        print("Rain tacos!")
        return "tis was true"
    end
    return "tis was false"
end
```

On the client:
```lua
local tacoRemote = main.modules.Remote.new("RainTacos")
tacoRemote:invokeServer("hello its me")
    :andThen(function(success)
        print("Success = ", success)
        if success then
            print("It rained tacos yay!")
        end
    end)
    :catch(function(errorMessage)
        warn("Something went wrong:", errorMessage)
    end)
```

--]]