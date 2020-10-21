-- Thread
-- Snippets of code used from:
	-- Author: Stephen Leitnick
	-- Source: https://github.com/Sleitnick/AeroGameFramework/blob/3465830523f3ee1fc326681d618e7bdd98153655/src/ReplicatedStorage/Aero/Shared/Thread.lua
	-- License: MIT (https://github.com/Sleitnick/AeroGameFramework/blob/master/LICENSE)


-- LOCAL
local main = require(game.HDAdmin)
local Thread = {}
local heartbeat = main.RunService.Heartbeat
local intervalTypes = {
	["Heartbeat"] = heartbeat,
	["RenderStepped"] = main.RunService.RenderStepped,
	["Stepped"] = main.RunService.Stepped,
}



-- LOCAL FUNCTIONS
local function createThread()
	local thread = {}
	thread.state = main.enum.ThreadState.Playing
	thread.completed = main.modules.Signal.new()
	thread.startTime = tick()
	thread.executeTime = nil
	thread.remainingTime = nil
	thread.connection = nil
	
	local function isDead(state)
		return state == main.enum.ThreadState.Completed or state == main.enum.ThreadState.Cancelled
	end
	local function checkDead(state)
		if isDead(state) then
			error("Cannot call a dead thread!")
		end
	end
	
	function thread:pause()
		checkDead(thread.state)
		thread.connection:Disconnect()
		thread.connection = nil
		thread.remainingTime = (thread.executeTime and thread.executeTime - tick()) or 0
	end
	thread.Pause = thread.pause
	thread.yield = thread.pause
	thread.Yield = thread.pause

	function thread:resume()
		checkDead(thread.state)
		thread.executeTime = tick() + (thread.remainingTime or 0)
		thread.connection = thread.frameEvent:Connect(thread.behaviour)
	end
	thread.Resume = thread.resume
	thread.play = thread.resume
	thread.Play = thread.resume
	
	function thread:cancel()
		thread:disconnect(true)
	end
	thread.Cancel = thread.cancel
	
	function thread:disconnect(incomplete)
		checkDead(thread.state)
		local originalState = thread.state
		local newState
		if isDead(originalState) then
			return false
		elseif incomplete then
			newState = main.enum.ThreadState.Cancelled
		else
			newState = main.enum.ThreadState.Completed
		end
		if originalState ~= main.enum.ThreadState.Paused then
			thread.connection:Disconnect()
		end
		thread.state = newState
		thread.completed:Fire(newState)
		thread.completed:Destroy()
		return true
	end
	thread.Disconnect = thread.disconnect
	thread.destroy = thread.disconnect -- this is so Maids can clean
	thread.Destroy = thread.disconnect
	
	return thread
end

local function loopMaster(intervalTime, thread, behaviour, func, ...)
	thread.remainingTime = intervalTime
	thread.frameEvent = intervalTypes[intervalTime] or heartbeat
	thread.behaviour = behaviour
	thread:resume()
	return thread
end



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
	local thread = createThread()
	thread.frameEvent = heartbeat
	thread.behaviour = function()
		thread:disconnect()
		func(table.unpack(args, 1, args.n))
	end
	thread:resume()
	return thread
end

function Thread.delay(waitTime, func, ...)
	local args = table.pack(...)
	local thread = createThread()
	thread.remainingTime = waitTime
	thread.frameEvent = heartbeat
	thread.behaviour = function()
		if (tick() >= thread.executeTime) then
			thread:disconnect()
			func(table.unpack(args, 1, args.n))
		end
	end
	thread:resume()
	return thread
end

function Thread.delayLoop(intervalTimeOrType, func, ...)
	local args = table.pack(...)
	local thread = createThread()
	local intervalTime = tonumber(intervalTimeOrType) or 0
	return loopMaster(intervalTime, thread, function()
		if (tick() >= thread.executeTime) then
			thread.executeTime = tick() + intervalTime
			func(table.unpack(args, 1, args.n))
		end
	end, func, ...)
end
Thread.delayRepeat = Thread.delayLoop

function Thread.loop(intervalTimeOrType, func, ...)
	func(...)
	return Thread.delayLoop(intervalTimeOrType, func, ...)
end

function Thread.loopUntil(intervalTimeOrType, criteria, func, ...)
	local args = table.pack(...)
	local thread = createThread()
	local intervalTime = tonumber(intervalTimeOrType) or 0
	func(table.unpack(args, 1, args.n))
	return loopMaster(intervalTime, thread, function()
		if criteria() then
			thread:disconnect()
		elseif (tick() >= thread.executeTime) then
			thread.executeTime = tick() + intervalTime
			func(table.unpack(args, 1, args.n))
		end
	end, func, ...)
end

function Thread.loopFor(intervalTimeOrType, iterations, func, ...)
	if iterations <= 0 then return end
	local args = table.pack(...)
	local thread = createThread()
	local intervalTime = tonumber(intervalTimeOrType) or 0
	local i = 1
	func(i, table.unpack(args, 1, args.n))
	return loopMaster(intervalTime, thread, function()
		if i == iterations then
			thread:disconnect()
		elseif (tick() >= thread.executeTime) then
			thread.executeTime = tick() + intervalTime
			i = i + 1
			func(i, table.unpack(args, 1, args.n))
		end
	end, func, ...)
end



return Thread