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
	self.maid = maid
	for k,v in pairs(properties or {}) do
		self[k] = v
	end
	
	self.command = (main.isServer and main.services.CommandService.getCommand(self.commandName)) or main.modules.ClientCommands[self.commandName]
	self.threads = {}
	self.isPaused = false
	self.isDead = false
	self.executing = false
	self.executionCompleted = maid:give(Signal.new())
	self.executionThreadsCompleted = maid:give(Signal.new())

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
function Task:begin()
	local sortedActionModifiers = {}
	local totalModifiers = 0
	for _, otherModifier in pairs(main.modules.Modifiers.sortedOrderArray) do
		if self.modifiers[otherModifier.name] and otherModifier.action then
			table.insert(sortedActionModifiers, otherModifier)
			totalModifiers += 1
		end
	end
	local Thread = main.modules.Thread
	if totalModifiers == 0 then
		self:execute()
			:andThen(function()
				self:kill()
			end)
	else
		
	end
end

function Task:execute()
	if self.executing then return end
	self.executing = true

	local command = self.command
	local firstCommandArg = command.args[1]
	local firstArgItem = main.modules.Args.dictionary[firstCommandArg]

	-- Convert arg strings into arg values
	local parsedArgs = {}
	for i, argString in pairs(self.args) do
		local argName = command.args[i]
		local argItem = main.modules.Args.dictionary[argName]
		local parsedArg = argItem:parse(argString)
		table.insert(parsedArgs, parsedArg)
	end

	local invokedCommand = false
	local function invokeCommand(argsToSend)
		main.modules.Thread.spawnNow(function()
			command:invoke(self, argsToSend)
		end)
		invokedCommand = true
	end
	
	-- If the task is player-specific (such as in ;kill foreverhd, ;kill all) find the associated player and execute the command on them
	local targetPlayer
	if self.userId then
		targetPlayer = main.Players:GetPlayerByUserId(self.userId)
		return invokeCommand({targetPlayer, table.unpack(parsedArgs)})
	end
	
	-- If the task has no associated player or qualifiers (such as in ;music <musicId>) then simply execute right away
	if not firstArgItem.playerArg then
		return invokeCommand(parsedArgs)
	end

	-- If the task has no associated player *but* does contain qualifiers (such as in ;globalKill all)
	-- If the firstArg has executeForEachPlayer, convert the task into subtasks for each player returned by the qualifiers
	local targets = firstArgItem:parse(self.qualifiers)
	if firstArgItem.executeForEachPlayer then
		-- Convert these into tasks themselves
		for i, plr in pairs(targets) do
			local TaskService = main.services.TaskService
			local properties = TaskService.generateRecord()
			properties.caller = self.caller
			properties.commandName = self.commandName
			properties.args = self.args
			properties.userId = plr.UserId
			local subtask = TaskService.createTask(false, properties)
			subtask:begin()
		end
	else
		invokeCommand({targets, table.unpack(parsedArgs)})
	end

	local Promise = main.modules.Promise
	return Promise.new(function(resolve, reject)
		if invokedCommand then
			self.executionThreadsCompleted:Wait()
			local humanoid = main.modules.PlayerUtil.getHumanoid(targetPlayer)
			if humanoid and humanoid.Health == 0 then
				local promise = Promise.new(function(resolve, reject)
					targetPlayer.CharacterAdded:Wait()
					resolve()
				end)
				promise:timeout(5)
				promise:await()
			end
			self.executionCompleted:Fire()
			self.executing = false
		end
	end)
end

function Task:filterTextArgs()
	--[[ filter thingy mbobies
	local ChatService = main.services.ChatService
	local messageObject = ChatService.getTextObject(message, sender.UserId)
	if messageObject then
		local filteredMessage = getFilteredMessage(messageObject, recipient.UserId)
		sendMessageEvent:FireClient(recipient, sender, message)
	end
	--]]
end

function Task:track(thread, ignoreFromCount)
	if self.isDead then
		thread:Destroy() --thread:disconnect()
		return thread
	elseif self.isPaused then
		thread:Pause() --thread:pause()
	end
	self.maid:give(thread)
	self.threads[thread] = true
	if not ignoreFromCount then
		self.totalThreads += 1
		main.modules.Thread.spawnNow(function()
			thread.Completed:Wait() --thread.completed:Wait()
			self.totalThreads -= 1
			if self.totalThreads == 0 then
				self.executionThreadsCompleted:Fire()
			end
		end)
	end
	return thread
end

function Task:pause()
	for thread, _ in pairs(self.threads) do
		thread:Pause() --thread:pause()
	end
	self.isPaused = true
end

function Task:resume()
	for thread, _ in pairs(self.threads) do
		thread:Play() --thread:resume()
	end
	self.isPaused = false
end

function Task:kill()
	if not self.isDead and self.command.revoke then
		self.command:revoke()
	end
	self.isDead = true
	self.maid:clean()
end
Task.destroy = Task.kill
Task.Destroy = Task.kill



return Task