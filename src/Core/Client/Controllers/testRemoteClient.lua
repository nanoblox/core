--[[
print("------------- Setup client -------------")
local main = require(game.Nanoblox)
local tacoRemote = main.modules.Remote.new("RainTacos")
tacoRemote.onClientInvoke = function(...)
    print("wow the client was invoked: ", ...)
    wait(1)
    return "yolooooooo"
end--]]

return {}