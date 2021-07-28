-- Thread
-- Snippets of code used from:
	-- Author: Stephen Leitnick
	-- Source: https://github.com/Sleitnick/AeroGameFramework/blob/3465830523f3ee1fc326681d618e7bdd98153655/src/ReplicatedStorage/Aero/Shared/Thread.lua
	-- License: MIT (https://github.com/Sleitnick/AeroGameFramework/blob/master/LICENSE)


-- LOCAL
local main = require(game.Nanoblox)
local Thread = {}
local intervalTypes = {
	["Heartbeat"] = true,
	["RenderStepped"] = true,
	["Stepped"] = true,
	["PreRender "] = true,
	["PreAnimation"] = true,
	["PreSimulation "] = true,
	["PostSimulation "] = true,
}



-- LOCAL FUNCTIONS
local activeFrameEvents = {}
local function formConnection(thread)
	-- This ensures only 1 connectin is formed per server, instead of per thread, so that thread behaviours can be executed in order of construction

	local frameEvent = thread.frameEvent
	local activeDetail = activeFrameEvents[frameEvent]
	if not activeDetail then
		activeDetail = {
			threadsToCheck = {},
			threadIndexesToRemove = {},
			totalThreadsToCheck = 0,
			runServiceConnection = main.RunService[frameEvent]:Connect(function()
				-- Deferred events means the connection may not be instantly disconnected
				if not activeDetail.runServiceConnection then
					return
				end
				-- This executes the threads behaviour
				local threadsToCheck = activeDetail.threadsToCheck
				for _, threadToCheck in pairs(threadsToCheck) do
					local funcToExecute, args = threadToCheck.behaviour()
					if funcToExecute then
						main.modules.Thread.spawnNow(funcToExecute, unpack(args, 1, args.n))
					end
				end
				-- This checks if any threads need removing
				local indexesToRemove = activeDetail.threadIndexesToRemove
				if #indexesToRemove > 0 then
					table.sort(indexesToRemove, function(a,b) -- This ensures the values are removed backwards (therefore remain the same index)
						return a > b
					end)
					for _, index in pairs(indexesToRemove) do
						table.remove(threadsToCheck, index)
					end
					activeDetail.threadIndexesToRemove = {}
				end
				-- This ends the runServiceConnection if no threads remain
				if activeDetail.totalThreadsToCheck == 0 then
					activeDetail.runServiceConnection:Disconnect()
					activeDetail.runServiceConnection = nil
					activeFrameEvents[frameEvent] = nil
				end
			end),
		}
		activeFrameEvents[frameEvent] = activeDetail
	end
	activeDetail.totalThreadsToCheck += 1
	table.insert(activeDetail.threadsToCheck, thread)
	----------------!!! RMOEVE
	local tableOfNames = {}
	for _, threadToCheck in pairs(activeDetail.threadsToCheck) do
		if threadToCheck.name then
			table.insert(tableOfNames, ("%s (%s)"):format(threadToCheck.name, thread.executeTime))
		end
	end
	--print("threadsToCheck = ", table.concat(tableOfNames, ", "))
	----------------!!! RMOEVE

	local connection = {}
	function connection:Disconnect()
		for i, threadToCheck in pairs(activeDetail.threadsToCheck) do
			if threadToCheck.connection == connection then
				table.insert(activeDetail.threadIndexesToRemove, i)
				break
			end
		end
		activeDetail.totalThreadsToCheck -= 1
		thread.connection = nil
	end
	thread.connection = connection

	return connection
end

local function createThread()

	-- Thread has multiple names for properties and methods to accurately mimic items like Tweens
	local thread = {}
	local function updateState(newState)
		thread.state = newState
		thread.PlaybackState = newState
	end

	updateState(main.enum.ThreadState.Playing)
	thread.completed = main.modules.Signal.new()
	thread.Completed = thread.completed -- this, and the method aliases, enable the easy-mimicking of TweenBases
	thread.startTime = tick()
	thread.executeTime = nil
	thread.remainingTime = nil
	thread.connection = nil
	thread.isDead = false -- equivalent to ``state == main.enum.ThreadState.Completed or state == main.enum.ThreadState.Cancelled``
	
	function thread:pause()
		if not thread.isDead then
			thread.connection:Disconnect()
			thread.connection = nil
			thread.remainingTime = (thread.executeTime and thread.executeTime - tick()) or 0
		end
	end
	thread.Pause = thread.pause
	thread.yield = thread.pause
	thread.Yield = thread.pause

	function thread:resume()
		if not thread.isDead then
			updateState(main.enum.ThreadState.Playing)
			thread.executeTime = tick() + (thread.remainingTime or 0)
			thread.connection = formConnection(thread)--thread.frameEvent:Connect(thread.behaviour)
		end
	end
	thread.Resume = thread.resume
	thread.play = thread.resume
	thread.Play = thread.resume
	
	function thread:setFrameEvent(name)
		thread.frameEvent = main.RunService[name]
		thread:pause()
		thread:resume()
	end

	function thread:cancel()
		thread:disconnect(true)
	end
	thread.Cancel = thread.cancel
	
	function thread:disconnect(incomplete)
		local originalState = thread.state
		local newState
		if thread.isDead then
			return false
		elseif incomplete then
			newState = main.enum.ThreadState.Cancelled
			thread.isDead = true
		else
			newState = main.enum.ThreadState.Completed
			thread.isDead = true
		end
		if originalState ~= main.enum.ThreadState.Paused then
			thread.connection:Disconnect()
		end
		updateState(newState)
		thread.completed:Fire(newState)
		thread.completed:Destroy()
		return true
	end
	thread.Disconnect = thread.disconnect
	thread.destroy = thread.disconnect -- this is so Janitors can clean
	thread.Destroy = thread.disconnect
	
	return thread
end

local function loopMaster(intervalTime, thread, behaviour, func, ...)
	thread.remainingTime = intervalTime
	thread.frameEvent = (intervalTypes[intervalTime] and intervalTime) or "Heartbeat"
	thread.behaviour = behaviour
	thread:resume()
	return thread
end



-- METHODS
function Thread.spawnNow(func, ...)
	-- Ideally avoid using spawnNow as it does not provide an as-accurate traceback (and in general is bad practise)
	-- Credit to BenSBK for this
	local thread = coroutine.create(func)
    local isSuccessful, result = coroutine.resume(thread, ...)
    if not isSuccessful then
        warn(string.format("%s\n%s", result, debug.traceback(thread)))
    end
end

function Thread.spawn(func, ...)
	local args = table.pack(...)
	local thread = createThread()
	thread.frameEvent = "Heartbeat"
	thread.behaviour = function()
		thread:disconnect()
		if func then
			return func, args
		end
	end
	thread:resume()
	return thread
end

function Thread.delay(waitTime, func, ...)
	local args = table.pack(...)
	local thread = createThread()
	thread.remainingTime = waitTime
	thread.frameEvent = "Heartbeat"
	thread.behaviour = function()
		if (tick() >= thread.executeTime) then
			thread:disconnect()
			if func then
				return func, args
			end
		end
	end
	thread:resume()
	return thread
end

function Thread.delayUntil(criteria, func, ...)
	local args = table.pack(...)
	local thread = createThread()
	thread.frameEvent = "Heartbeat"
	thread.behaviour = function()
		if criteria() then
			thread:disconnect()
			if func then
				return func, args
			end
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
			if func then
				return func, args
			end
		end
	end, func, ...)
end

function Thread.delayLoopUntil(intervalTimeOrType, criteria, func, ...)
	local args = table.pack(...)
	local thread = createThread()
	local intervalTime = tonumber(intervalTimeOrType) or 0
	return loopMaster(intervalTime, thread, function()
		if criteria() then
			thread:disconnect()
		elseif (tick() >= thread.executeTime) then
			thread.executeTime = tick() + intervalTime
			if func then
				return func, args
			end
		end
	end, func, ...)
end

function Thread.delayLoopFor(intervalTimeOrType, iterations, func, ...)
	if iterations <= 0 then return end
	local args = table.pack(...)
	local thread = createThread()
	local intervalTime = tonumber(intervalTimeOrType) or 0
	local i = 0
	return loopMaster(intervalTime, thread, function()
		if i >= iterations then
			thread:disconnect()
		elseif (tick() >= thread.executeTime) then
			thread.executeTime = tick() + intervalTime
			i = i + 1
			if func then
				local newArgs = table.pack(i, unpack(args, 1, args.n))
				return func, newArgs
			end
		end
	end, func, ...)
end



return Thread