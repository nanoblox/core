-- Thread
-- Author: Stephen Leitnick
-- Source: https://github.com/Sleitnick/AeroGameFramework/blob/3465830523f3ee1fc326681d618e7bdd98153655/src/ReplicatedStorage/Aero/Shared/Thread.lua
-- License: MIT (https://github.com/Sleitnick/AeroGameFramework/blob/master/LICENSE)
-- Modified for use in HDAdmin


-- LOCAL
local main = require(game.HDAdmin)
local Thread = {}
local heartbeat = main.RunService.Heartbeat



-- METHODS
function Thread.spawnNow(func, ...)
	--[[
		This method was originally written by Quenty and is slightly
		modified for this module. The original source can be found in
		the link below, as well as the MIT license:
			https://github.com/Quenty/NevermoreEngine/blob/version2/Modules/Shared/Utility/fastSpawn.lua
			https://github.com/Quenty/NevermoreEngine/blob/version2/LICENSE.md
	--]]
	local args = table.pack(...)
	local bindable = Instance.new("BindableEvent")
	bindable.Event:Connect(function() func(table.unpack(args, 1, args.n)) end)
	bindable:Fire()
	bindable:Destroy()
end

function Thread.spawn(func, ...)
	local args = table.pack(...)
	local hb
	hb = heartbeat:Connect(function()
		hb:Disconnect()
		func(table.unpack(args, 1, args.n))
	end)
end

function Thread.delay(waitTime, func, ...)
	local args = table.pack(...)
	local executeTime = (tick() + waitTime)
	local hb
	hb = heartbeat:Connect(function()
		if (tick() >= executeTime) then
			hb:Disconnect()
			func(table.unpack(args, 1, args.n))
		end
	end)
	return hb
end

function Thread.wait(waitTime)
	local continueTime = (tick() + waitTime)
	while tick() < continueTime do
		heartbeat:Wait()
	end
	return
end

function Thread.delayRepeat(intervalTime, func, ...)
	local args = table.pack(...)
	local nextExecuteTime = (tick() + intervalTime)
	local hb
	hb = heartbeat:Connect(function()
		if (tick() >= nextExecuteTime) then
			nextExecuteTime = (tick() + intervalTime)
			func(table.unpack(args, 1, args.n))
		end
	end)
	return hb
end



return Thread