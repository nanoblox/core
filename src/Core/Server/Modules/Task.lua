-- LOCAL
local main = require(game.Nanoblox)
local Maid = main.modules.Maid
local Signal = main.modules.Signal
local Task = {}
Task.__index = Task



-- CONSTRUCTOR
function Task.new(properties)
	local self = {}
	setmetatable(self, Task)
	
	local maid = Maid.new()
	self.masterMaid = maid
	for k,v in pairs(properties or {}) do
		self[k] = v
	end
	
	self.command = main.services.CommandService.getCommand(self.commandName)
	self.thisExecution = nil
	self.threads = {}
	self.isPaused = false
	self.isDead = false

	local qualifierPresent = false
	for k,v in pairs(self.qualifiers) do
		qualifierPresent = true
	end
	if not qualifierPresent then
		self.qualifiers = nil
	end
	
	return self
end



-- METHODS
function Task:execute()
	local command = self.command
	local firstCommandArg = command.args[1]

	-- Convert arg strings into arg values
	local parsedArgs = {}
	for i, argString in pairs(self.args) do
		local argName = command.args[i]
		local argItem = main.modules.Args.dictionary[argName]
		local parsedArg = argItem:parse(argString)
		table.insert(parsedArgs, parsedArg)
	end

	-- The ``this`` parameter passed through all commands
	-- This enables commands to reference their own table in additon to the task they're being called from
	local thisExecution
	local client = main.services.CommandService.Client.new(self.UID)
	thisExecution = {
		taskUID = self.UID,
		maid = self.masterMaid:give(main.modules.Maid.new()),
		client = client,
		-- This is vital in pausing and resuming tasks and their invoked commands
		active = true,
		_completed = self.masterMaid:give(main.modules.Signal.new()),
		_threadsTracking = 0,
		track = function(thread)
			if self.isDead or not thisExecution.active then
				-- Kill thread right away if task dead or execution inactive
				thread:disconnect()
			else
				-- Track thread
				main.modules.Thread.spawnNow(function()
					self.masterMaid:give(thread)
					self.threads[thread] = true
					thisExecution._threadsTracking = thisExecution._threadsTracking + 1
					if self.isPaused then
						-- Pause thread if the task is paused
						thread:pause()
					end
					thread.completed:Wait()
					self.threads[thread] = nil
					thisExecution._threadsTracking = thisExecution._threadsTracking - 1
				end)
			end
			return thread
		end,
	}
	-- Update thisExecution with command properties
	for k,v in pairs(command) do
		thisExecution[k] = v
	end
	self.this = thisExecution

	local function invokeCommand(argsToSend)
		self.thisExecution = thisExecution
		main.modules.Thread.spawnNow(function()
			command.invoke(thisExecution, self.caller, argsToSend)
			if thisExecution._threadsTracking > 0 then
				thisExecution._completed:Wait()
			end
			thisExecution.active = false
			if self.thisExecution == thisExecution then
				self.thisExecution = nil
			end
		end)
	end

	if self.userId then
		-- User specific task
		local targetPlayer = main.Players:GetPlayerByUserId(self.userId)
		local plrParsedArg = (firstCommandArg == "player" and targetPlayer) or {targetPlayer}
		invokeCommand({plrParsedArg, table.unpack(parsedArgs)})

	else
		-- Server task (which can still include players)
		local argItem = main.modules.Args.dictionary[firstCommandArg]
		if argItem.playerArg == true then
			-- Leading playerArg present (typically only occurs for global commands with a leader playerArg)
			local targets = argItem:parse(self.qualifiers)
			if firstCommandArg == "player" then
				-- Convert these into tasks themselves
				for i, plr in pairs(targets) do
					local TaskService = main.services.TaskService
					local properties = TaskService.generateRecord()
					properties.caller = self.caller
					properties.commandName = self.commandName
					properties.args = self.args
					properties.userId = plr.UserId
					TaskService.createTask(false, properties)
				end
			else
				invokeCommand({targets, table.unpack(parsedArgs)})
			end
		else
			-- Non-player related command, nice and easy to handle :)
			invokeCommand(parsedArgs)
		end
	end

	--[[ filter thingy mbobies
	local ChatService = main.services.ChatService
	local messageObject = ChatService.getTextObject(message, sender.UserId)
	if messageObject then
		local filteredMessage = getFilteredMessage(messageObject, recipient.UserId)
		sendMessageEvent:FireClient(recipient, sender, message)
	end
	--]]
end

function Task:pause()
	for thread, _ in pairs(self.threads) do
		thread:pause()
	end
	self.isPaused = true
end

function Task:resume()
	for thread, _ in pairs(self.threads) do
		thread:resume()
	end
	self.isPaused = false
end

function Task:destroy()
	self.isDead = true
	local this = self.thisExecution
	if this then
		self.thisExecution = nil
		this._completed:Fire()
	end
	self.masterMaid:clean()
end



return Task