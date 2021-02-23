local main = require(game.Nanoblox)
--[[
spawn(function()
    wait(10)
    print("------------- Fire server -------------")
    local tacoRemote = main.modules.Remote.new("RainTacos")
    local timedOut = false
    tacoRemote:invokeClient(game.Players:WaitForChild("ForeverHD"), "hello ben")
        :timeout(20, "TimedOut")
        :andThen(function(value)
            print("<andThen>")
            print("Client said:", value)
            return "Waffles"
        end)
        :catch(function(warning)
            print(warning)
            --return "Pancakes"
        end)
        :await(function(promise)
            print(promise.Status)
        end)
end)
--]]
--[[
local tacoRemote = main.modules.Remote.new("RainTacos", nil, nil, 101)
tacoRemote.onServerInvoke = function(...)
    print("SEVER INVOKE: ", ...)
end
--]]

return {}