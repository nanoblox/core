--[[

A task is an object which runs for the duration of a command. If you applied a walkspeed of 50 to a player for example the task will remain until that command is revoked.

--]]



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
	
	self.command = (main.isServer and main.services.CommandService.getCommand(self.commandName)) or main.modules.ClientCommands.get(self.commandName)
	self.threads = {}
	self.isPaused = false
	self.isDead = false
	self.begun = false
	self.executing = false
	self.totalExecutionThreads = 0
	self.executionThreadsCompleted = maid:give(Signal.new())
	self.executionCompleted = maid:give(Signal.new())
	self.callerLeft = maid:give(Signal.new())
	self.persistence = self.command.persistence
	self.trackingClients = {}
	self.totalReplications = 0
	self.replicationsThisSecond = 0
	self.buffs = {}

	local qualifierPresent = false
	if self.qualifiers then
		for k,v in pairs(self.qualifiers) do
			qualifierPresent = true
		end
	end
	if not qualifierPresent then
		self.qualifiers = nil
	end

	-- This handles the killing of tasks depending upon the command.persistence enum
	local targetPlayer = self.targetUserId and main.Players:GetPlayerByUserId(self.targetUserId)
	self.targetPlayer = targetPlayer
	if main.isServer then
		local validPlayerLeavingEnums = {
			[tostring(main.enum.Persistence.UntilPlayerDies)] = true,
			[tostring(main.enum.Persistence.UntilPlayerRespawns)] = true,
			[tostring(main.enum.Persistence.UntilPlayerLeaves)] = true,
			[tostring(main.enum.Persistence.UntilPlayerOrCallerLeave)] = true,
		}
		local validCallerLeavingEnums = {
			[tostring(main.enum.Persistence.UntilCallerLeaves)] = true,
			[tostring(main.enum.Persistence.UntilPlayerOrCallerLeave)] = true,
		}
		local function playerOrCallerRemoving(userId, leftFromThisServer)
			local persistence = tostring(self.persistence)
			local playerLeft = (userId == self.targetUserId and validPlayerLeavingEnums[persistence])
			local callerLeft = (userId == self.callerUserId and validCallerLeavingEnums[persistence])
			if playerLeft or callerLeft then
				if callerLeft and leftFromThisServer and self.modifiers.wasGlobal then
					-- We fire to other servers if the task was global so that the other globa tasks know the caller (based in this server) has left
					main.services.TaskService.callerLeftSender:fireOtherServers(userId)
				end
				self:kill()
			end
		end
		maid:give(main.Players.PlayerRemoving:Connect(function(plr)
			local userId = plr.UserId
			playerOrCallerRemoving(userId, true)
		end))
		maid:give(self.callerLeft:Connect(function()
			playerOrCallerRemoving(self.callerUserId)
		end))
		local function registerCharacter(char)
			if char then
				local humanoid = char:WaitForChild("Humanoid")
				local function died()
					if self.persistence == main.enum.Persistence.UntilPlayerDies then
						self:kill()
					end
				end
				if humanoid.Health <= 0 then
					died()
				else
					maid:give(humanoid.Died:Connect(function()
						died()
					end))
				end
			end
		end
		if targetPlayer then
			maid:give(targetPlayer.CharacterAdded:Connect(function(char)
				if self.persistence == main.enum.Persistence.UntilPlayerRespawns then
					self:kill()
					return
				end
				registerCharacter(char)
			end))
			main.modules.Thread.spawnNow(function()
				registerCharacter(targetPlayer.Character)
			end)
		end
	end

	-- This retrieves the agent
	if main.isServer then
		-- This determines the tasks agent when the player arg is present as the first arg
		local user = main.modules.PlayerStore:getUser(self.targetPlayer)
		if user then
			self.agent = user.agent
		end
	else
		-- This dynamically creates agents for client commands
		local agentDetail = main.clientCommandAgents[self.targetPlayer]
		if not agentDetail then
			agentDetail = {
				agent = main.modules.Agent.new(self.targetPlayer),
				activeAreas = 0,
			}
			main.clientCommandAgents[self.targetPlayer] = agentDetail
		end
		agentDetail.activeAreas +=1
		self.agent = agentDetail.agent
	end

	return self
end



-- CORE METHODS
function Task:begin()
	if self.begun or self.isDead then return end
	self.begun = true

	local sortedActionModifiers = {}
	local totalModifiers = 0
	for _, actionModifier in pairs(main.modules.Parser.Modifiers.sortedOrderArray) do
		if self.modifiers[actionModifier.name] and actionModifier.action then
			table.insert(sortedActionModifiers, actionModifier)
			totalModifiers += 1
		end
	end
	
	-- This ensures all modifiers and all executions have ended before killing the task
	local function afterExecution()
		if self.totalStartThreads and self.totalStartThreads > 0 then
			self.startThreadsCompleted:Wait()
		end
		if self.totalExecutionThreads and self.totalExecutionThreads > 0 then
			self.executionThreadsCompleted:Wait()
		end
		if self.persistence == main.enum.Persistence.None then
			self:kill()
		end
	end

	-- If no modifiers present, simply call execute once then kill the task
	if totalModifiers == 0 then
		self:execute()
			:andThen(function()
				afterExecution()
			end)
			:catch(function(warning)
				warn(warning)
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
		afterExecution()
	end)
end

function Task:execute()
	local Promise = main.modules.Promise
	if self.executing or self.isDead then
		return Promise.defer(function(_, reject)
			reject("Execution already running!")
		end)
	end
	self.executing = true

	local command = self.command
	local firstCommandArg
	local firstArgItem
	if self.args then
		firstCommandArg = command.args[1]
		firstArgItem = main.modules.Parser.Args.get(firstCommandArg)
	end

	local invokedCommand = false
	local function invokeCommand(parseArgs, ...)
		local additional = table.pack(...)
		invokedCommand = true
		
		-- Convert arg strings into arg values
		-- Only execute the command once all args have been converted
		-- Some arg parsers, such as text, may be aschronous due to filter requests
		local promises = {}
		local filteredAllArguments = false
		if main.isServer and parseArgs and self.args then
			local currentArgs = additional[1]
			local parsedArgs = (type(currentArgs) == "table" and currentArgs)
			if not parsedArgs then
				parsedArgs = {}
				additional[1] = parsedArgs
			end
			local i = #parsedArgs + 1
			for _, argString in pairs(self.args) do
				local argName = command.args[i]
				local argItem = main.modules.Parser.Args.get(argName)
				if argItem.playerArg then
					argString = {
						[argString] = {}
					}
				end
				local promise = main.modules.Promise.new(function(resolve, reject)
					resolve(argItem:parse(argString, self.callerUserId, self.targetUserId))
				end)
				table.insert(promises, promise
					:andThen(function(parsedArg)
						table.insert(parsedArgs, parsedArg)
					end)
				)
				i += 1
			end
		end
		main.modules.Promise.all(promises)
			:finally(function()
				filteredAllArguments = true
			end)
		
		local finishedInvokingCommand = false
		self:track(main.modules.Thread.delayUntil(function() return finishedInvokingCommand == true end))
		self:track(main.modules.Thread.delayUntil(function() return filteredAllArguments == true end, function()
			command.invoke(self, table.unpack(additional))
			finishedInvokingCommand = true
		end))
	end
	
	main.modules.Thread.spawnNow(function()

		-- If client task, execute with task.clientArgs
		if main.isClient then
			return invokeCommand(false, table.unpack(self.clientArgs))
		end

		-- If the task is player-specific (such as in ;kill foreverhd, ;kill all) find the associated player and execute the command on them
		if self.targetPlayer then
			return invokeCommand(true, {self.targetPlayer})
		end
		
		-- If the task has no associated player or qualifiers (such as in ;music <musicId>) then simply execute right away
		if not firstArgItem.playerArg then
			return invokeCommand(true, {})
		end

		-- If the task has no associated player *but* does contain qualifiers (such as in ;globalKill all)
		local targets = firstArgItem:parse(self.qualifiers, self.callerUserId)
		if firstArgItem.executeForEachPlayer then -- If the firstArg has executeForEachPlayer, convert the task into subtasks for each player returned by the qualifiers
			for i, plr in pairs(targets) do
				--self:track(main.modules.Thread.delayUntil(function() return self.filteredAllArguments == true end, function()
					local TaskService = main.services.TaskService
					local properties = TaskService.generateRecord()
					properties.callerUserId = self.callerUserId
					properties.commandName = self.commandName
					properties.args = self.args
					properties.targetUserId = plr.targetUserId
					local subtask = TaskService.createTask(false, properties)
					subtask:begin()
				--end))
			end
		else
			invokeCommand(true, {targets})
		end

	end)
	
	return Promise.defer(function(resolve)
		if invokedCommand then
			self.executionThreadsCompleted:Wait()
			local humanoid = main.modules.PlayerUtil.getHumanoid(self.targetPlayer)
			if humanoid and humanoid.Health == 0 then
				local promise = Promise.new(function(charResolve)
					self.targetPlayer.CharacterAdded:Wait()
					charResolve()
				end)
				promise:timeout(5)
				promise:await()
			end
		end
		self.executionCompleted:Fire()
		self.executing = false
		resolve()
	end)
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
		main.RunService.Heartbeat:Wait()
		self[newCountPropertyName] -= 1
		if self[newCountPropertyName] == 0 and self[newCompletedSignalName] and not self.isDead then
			self[newCompletedSignalName]:Fire()
		end
	end)
	return thread
end

function Task:pause()
	for thread, _ in pairs(self.threads) do
		thread:Pause() --thread:pause()
	end
	self:pauseAllClients()
	self.isPaused = true
end

function Task:resume()
	for thread, _ in pairs(self.threads) do
		thread:Play() --thread:resume()
	end
	self:resumeAllClients()
	self.isPaused = false
end

function Task:kill()
	if self.isDead then return end
	if not self.isDead and self.command.revoke then
		if self.revokeArguments then
			self.command.revoke(self, table.unpack(self.revokeArguments))
		else
			self.command.revoke(self)
		end
	end
	self.isDead = true
	self:clearBuffs()
	self.maid:clean()
	if main.isServer then
		self:revokeAllClients()
		if not self.modifiers.perm then --self._global == false then
			main.services.TaskService.removeTask(self.UID)
		end
	else
		-- This dynamically removes agents for client commands
		local agentDetail = main.clientCommandAgents[self.targetPlayer]
		if agentDetail then
			agentDetail.activeAreas -=1
			if agentDetail.activeAreas <= 0 then
				agentDetail.agent:destroy()
				main.clientCommandAgents[self.targetPlayer] = nil
			end
		end
	end
end
Task.destroy = Task.kill
Task.Destroy = Task.kill

-- An abstraction of ``task.maid:give(...)``
function Task:give(...)
	return self.maid:give(...)
end

-- An abstraction of ``task:track(main.modules.Thread.delay(waitTime, func, ...))``
function Task:delay(waitTime, func, ...)
	return self:track(main.modules.Thread.delay(waitTime, func, ...))
end

-- An abstraction of ``task:track(main.modules.Thread.delayUntil(criteria, func, ...))``
function Task:delayUntil(criteria, func, ...)
	return self:track(main.modules.Thread.delayUntil(criteria, func, ...))
end

-- An abstraction of ``task:track(main.modules.Thread.delayLoop(intervalTimeOrType, func, ...))``
function Task:delayLoop(intervalTimeOrType, func, ...)
	return self:track(main.modules.Thread.delayLoop(intervalTimeOrType, func, ...))
end

-- An abstraction of ``task:track(main.modules.Thread.delayLoopUntil(intervalTimeOrType, criteria, func, ...))``
function Task:delayLoopUntil(intervalTimeOrType, criteria, func, ...)
	return self:track(main.modules.Thread.delayLoopUntil(intervalTimeOrType, criteria, func, ...))
end

-- An abstraction of ``task:track(main.modules.Thread.delayLoopFor(intervalTimeOrType, iterations, func, ...))``
function Task:delayLoopFor(intervalTimeOrType, iterations, func, ...)
	return self:track(main.modules.Thread.delayLoopFor(intervalTimeOrType, iterations, func, ...))
end

-- An abstraction of ``task.agent:buff(...)``
function Task:buff(effect, value, optionalTweenInfo)
	local agent = self.agent
	if not agent then
		error("Cannot create buff as the task has no associated player!")
	end
	local buff = agent:buff(effect)
	if value then
		buff:set(value, optionalTweenInfo)
	end
	table.insert(self.buffs, buff)
	return buff
end

function Task:clearBuffs()
	for _, buff in pairs(self.buffs) do
		if not buff.isDestroyed then
			buff:destroy()
		end
	end
	self.buffs = {}
end



-- SERVER NETWORKING METHODS
local SERVER_ONLY_WARNING = "this method can only be called on the server!"
function Task:_invoke(playersArray, ...)
	assert(main.isServer, SERVER_ONLY_WARNING)

	local TIMEOUT_MAX = 90
	local GROUP_TIMEOUT = 3
	local GROUP_TIMEOUT_PERCENT = 0.8
	-- This invokes all targeted players to execute the corresponding client command
	-- If no persistence, then wait until these clients have completed their client sided execution before ending the server task
	-- To prevent abuse:
		-- 1. Cap a timeout of TIMEOUT_MAX seconds. If not heard back after this time, force end invocation
		-- 2. As soon as GROUP_TIMEOUT_PERCENT of clients have responded, wait GROUP_TIMEOUT then automatically force end all remaining invocations
		-- 3. If a player leaves its invocation is automatically ended
	
	local promises = {}
	local killAfterExecution = self.persistence == main.enum.Persistence.None
	local timeoutValue = (killAfterExecution and TIMEOUT_MAX) or 0
	local totalClients = #playersArray
	local responses = 0
	self:track(main.modules.Thread.delayUntil(function() return responses == totalClients end)) -- This keeps the task alive until the client execution has complete or timeout exceeded
	for _, player in pairs(playersArray) do
		self.trackingClients[player] = true
		local clientTaskProperties = {
			UID = self.UID,
			commandName = self.commandName,
			killAfterExecution = killAfterExecution,
			clientArgs = table.pack(...),
			targetUserId = self.targetUserId,
			targetPlayer = self.targetPlayer,
			callerUserId = self.callerUserId,
		}
		table.insert(promises, main.services.TaskService.remotes.invokeClientCommand:invokeClient(player, clientTaskProperties)
			:timeout(timeoutValue)
			:finally(function()
				responses += 1
				if killAfterExecution then
					main.RunService.Heartbeat:Wait()
					self.trackingClients[player] = nil
				end
			end)
		)
	end
	local minimumResponses = math.floor(totalClients * GROUP_TIMEOUT_PERCENT)
	if minimumResponses < 1 then
		minimumResponses = 1
	end
	main.modules.Promise.some(promises, minimumResponses)
		:finally(function()
			if responses ~= totalClients then
				main.modules.Thread.delay(GROUP_TIMEOUT, function()
					for _, promise in pairs(promises) do
						promise:cancel()
					end
				end)
			end
		end)
end

function Task:invokeClient(player, ...)
	local playersArray = {player}
	self:_invoke(playersArray, ...)
end

function Task:invokeNearbyClients(origin, radius, ...)
	local playersArray = main.enum.TargetPool.getProperty("Nearby")(origin, radius)
	self:_invoke(playersArray, ...)
end

function Task:invokeAllClients(...)
	local playersArray = main.Players:GetPlayers()
	self:_invoke(playersArray, ...)
end

function Task:invokeFutureClients(...)
	local args = table.pack(...)
	self.maid:give(main.Players.PlayerAdded:Connect(function(player)
		self:invokeClient(player, table.unpack(args))
	end))
end

function Task:invokeAllAndFutureClients(...)
	self:invokeAllClients(...)
	self:invokeFutureClients(...)
end

function Task:_revoke(playersArray, ...)
	assert(main.isServer, SERVER_ONLY_WARNING)
	for _, player in pairs(playersArray) do
		main.services.TaskService.remotes.revokeClientCommand:fireClient(player, self.UID, ...)
		self.trackingClients[player] = nil
	end
end

function Task:revokeClient(player, ...)
	local playersArray = {}
	if self.trackingClients[player] then
		table.insert(playersArray, player)
	end
	self:_revoke(playersArray, ...)
end

function Task:revokeAllClients(...)
	local playersArray = {}
	for trackingPlayer, _ in pairs(self.trackingClients) do
		table.insert(playersArray, trackingPlayer)
	end
	self:_revoke(playersArray, ...)
end

function Task:pauseAllClients()
	assert(main.isServer, SERVER_ONLY_WARNING)
	for trackingPlayer, _ in pairs(self.trackingClients) do
		main.services.TaskService.remotes.callClientTaskMethod:fireClient(trackingPlayer, self.UID, "pause")
	end
end

function Task:resumeAllClients()
	assert(main.isServer, SERVER_ONLY_WARNING)
	for trackingPlayer, _ in pairs(self.trackingClients) do
		main.services.TaskService.remotes.callClientTaskMethod:fireClient(trackingPlayer, self.UID, "resume")
	end
end



-- CLIENT NETWORKING METHODS
local CLIENT_ONLY_WARNING = "this method can only be called on the client!"
function Task:_replicate(targetPool, packedArgs, packedData)
	assert(main.isClient, CLIENT_ONLY_WARNING)
	main.controllers.CommandController.replicationRequest:fireServer(self.UID, targetPool, packedArgs, packedData)
end

function Task:replicateTo(player, ...)
	self:_replicate(main.enum.TargetPool.Individual, {player}, table.pack(...))
end

function Task:replicateToNearby(origin, radius, ...)
	self:_replicate(main.enum.TargetPool.Nearby, {origin, radius}, table.pack(...))
end

function Task:replicateToOthers(...)
	self:_replicate(main.enum.TargetPool.Others, {}, table.pack(...))
end

function Task:replicateToOthersNearby(origin, radius, ...)
	self:_replicate(main.enum.TargetPool.OthersNearby, {origin, radius}, table.pack(...))
end

function Task:replicateToAll(...)
	self:_replicate(main.enum.TargetPool.All, {}, table.pack(...))
end

function Task:replicateToServer(...)
	self:_replicate(main.enum.TargetPool.None, {}, table.pack(...))
end



return Task