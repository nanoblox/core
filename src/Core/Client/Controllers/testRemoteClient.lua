local main = require(game.Nanoblox)

--[[
print("------------- Setup client -------------")
local tacoRemote = main.modules.Remote.new("RainTacos")
tacoRemote.onClientInvoke = function(...)
    print("wow the client was invoked: ", ...)
    wait(1)
    return "yolooooooo"
end--]]

--[[
spawn(function()
    local tacoRemote = main.modules.Remote.new("RainTacos")
    for i = 1, 1000000 do
        for i2 = 1, 1 do
            local info = {
                HellOWorld = CFrame.new(1,2,30000000000000),
                HellOWorld2 = "test message",
                HellOWorld3 = "test message",
                HellOWorld4 = "test message",
                HellOWorld5 = "test message",
            } --("Hello ben - %s.%s"):format(i, i2)
            tacoRemote:invokeServer(info)
                :catch(function()
                    
                end)
            --wait()
        end
        wait(0.5)
    end
end)--]]


return {}