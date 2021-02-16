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
	self.begun = false
	self.executing = false
	self.totalExecutionThreads = 0
	self.executionThreadsCompleted = maid:give(Signal.new())
	self.executionCompleted = maid:give(Signal.new())

	local qualifierPresent = false
	for k,v in pairs(self.qualifiers) do
		qualifierPresent = true
	end
	if not qualifierPresent then
		self.qualifiers = nil
	end
	
	return self
end



-- CORE METHODS
function Task:begin()
	if self.begun then return end
	self.begun = true

	local sortedActionModifiers = {}
	local totalModifiers = 0
	for _, actionModifier in pairs(main.modules.Modifiers.sortedOrderArray) do
		if self.modifiers[actionModifier.name] and actionModifier.action then
			table.insert(sortedActionModifiers, actionModifier)
			totalModifiers += 1
		end
	end
	
	-- If no modifiers present, simply call execute once then kill the task
	if totalModifiers == 0 then
		self:execute()
			:andThen(function()
				self:kill()
			end)
		return
	end
	
	main.modules.Thread.spawnNow(function()
		-- This handles the applying of all modifiers, tracks them, then kills the task when all modifiers have completed
		local function track(thread)
			self:track(thread, "totalStartThreads", "startThreadsCompleted")
		end
		local previousExecuteAfterThread
		for _, actionModifier in pairs(sortedActionModifiers) do
			local thread = actionModifier.action(self, self.modifiers[actionModifier.name])
			if thread then
				track(thread)
				-- if previousExecuteAfterThread is true then don't call this otherwise task will be called twice in the same frame unnecessarily
				if actionModifier.executeRightAway and not previousExecuteAfterThread then
					self:execute()
				end
				if actionModifier.executeAfterThread then
					local afterThreadConnection
					afterThreadConnection = thread.completed:Connect(function()
						afterThreadConnection:Disconnect()
						self:execute()
					end)
				end
				if actionModifier.yieldUntilThreadComplete then
					thread.completed:Wait()
				end
				previousExecuteAfterThread = actionModifier.executeAfterThrea
			end
		end
		-- This ensures all modifiers and all executions have ended before killing the task
		if self.totalStartThreads > 0 then
			self.startThreadsCompleted:Wait()
		end
		if self.totalExecutionThreads > 0 then
			self.executionThreadsCompleted:Wait()
		end
		self:kill()
	end)
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
	local targets = firstArgItem:parse(self.qualifiers)
	if firstArgItem.executeForEachPlayer then -- If the firstArg has executeForEachPlayer, convert the task into subtasks for each player returned by the qualifiers
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

function Task:track(thread, countPropertyName, completedSignalName)
	local newCountPropertyName = countPropertyName or "totalExecutionThreads"
	local newCompletedSignalName = completedSignalName or "executionThreadsCompleted"
	if not self[newCountPropertyName] then
		self[newCountPropertyName] = 0
	end
	if not self[newCompletedSignalName] then
		self[newCompletedSignalName] = self.maid:give(Signal.new())
	end
	if self.isDead then
		thread:Destroy() --thread:disconnect()
		return thread
	elseif self.isPaused then
		thread:Pause() --thread:pause()
	end
	self.maid:give(thread)
	self.threads[thread] = true
	self[newCountPropertyName] += 1
	main.modules.Thread.spawnNow(function()
		thread.Completed:Wait() --thread.completed:Wait()
		self[newCountPropertyName] -= 1
		if self[newCountPropertyName] == 0 then
			self[newCompletedSignalName]:Fire()
		end
	end)
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
	if self.isDead then return end
	if not self.isDead and self.command.revoke then
		self.command:revoke()
	end
	self.isDead = true
	self.maid:clean()
	if main.isServer and not self.modifiers.perm then--self._global == false then
		main.services.TaskService.removeTask(self.UID)
	end
end
Task.destroy = Task.kill
Task.Destroy = Task.kill



-- SERVER NETWORKING METHODS
local SERVER_ONLY_WARNING = "this method can only be called on the server!"
function Task:invokeClient(player, ...)
	assert(main.isServer, SERVER_ONLY_WARNING)
end

function Task:invokeNearbyClients(origin, radius, ...)
	assert(main.isServer, SERVER_ONLY_WARNING)
end

function Task:invokeAllClients(...)
	assert(main.isServer, SERVER_ONLY_WARNING)
end

function Task:revokeClient(player, ...)
	assert(main.isServer, SERVER_ONLY_WARNING)
end

function Task:revokeAllClients(...)
	assert(main.isServer, SERVER_ONLY_WARNING)
end



-- CLIENT NETWORKING METHODS
local CLIENT_ONLY_WARNING = "this method can only be called on the client!"
function Task:replicateTo(player, ...)
	assert(main.isClient, CLIENT_ONLY_WARNING)
end

function Task:replicateToNearby(origin, radius, ...)
	assert(main.isClient, CLIENT_ONLY_WARNING)
end

function Task:replicateToAll(...)
	assert(main.isClient, CLIENT_ONLY_WARNING)
end



return Task