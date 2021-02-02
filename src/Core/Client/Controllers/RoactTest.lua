-- LOCAL
local main = require(game.HDAdmin)
local module = {}
local Roact = main.modules.Roact
	


-- Create a function that creates the elements for our UI.
-- Later, we'll use components, which are the best way to organize UI in Roact.
local function clock(currentTime)
    return Roact.createElement("ScreenGui", {}, {
        TimeLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "Time Elapsed: " .. currentTime
        })
    })
end


-- Create our initial UI.
--[[
local currentTime = 0
local handle = Roact.mount(clock(currentTime), main.localPlayer.PlayerGui, "Clock UI")

-- Every second, update the UI to show our new time.
while true do
    wait(1)

    currentTime = currentTime + 1
    handle = Roact.update(handle, clock(currentTime))
end--]]



return module