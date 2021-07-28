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
	self.commandName = (main.isServer and self.command.name) or self.commandName
	self.hijackedCommandName = nil
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
	self.cooldown = (main.isServer and tonumber(self.command.cooldown) or 0)
	self.trackingClients = {}
	self.totalReplicationRequests = 0
	self.replicationRequestsThisSecond = 0
	self.buffs = {}
	self.originalArgReturnValues = {}
	self.originalArgReturnValuesFromIndex = {}
	self.trackingItems = {}
	self.anchoredParts = {}
	maid:give(function()
		self.anchoredParts = nil
	end)

	self.tags = {}
	if main.isServer then
		local tags = self.command.tags or {}
		for _, tagName in pairs(tags) do
			self.tags[tagName:lower()] = true
		end
	end

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
	self.player = self.player or (self.playerUserId and main.Players:GetPlayerByUserId(self.playerUserId))
	self.caller = self.caller or (self.callerUserId and main.Players:GetPlayerByUserId(self.callerUserId))

	local validPlayerLeavingEnums = {
		[tostring(main.enum.Persistence.UntilPlayerDies)] = true,
		[tostring(main.enum.Persistence.UntilPlayerRespawns)] = true,
		[tostring(main.enum.Persistence.UntilPlayerLeaves)] = true,
		[tostring(main.enum.Persistence.UntilPlayerOrCallerLeave)] = true,
	}
	local validCallerLeavingEnums = {
		[tostring(main.enum.Persistence.UntilCallerDies)] = true,
		[tostring(main.enum.Persistence.UntilCallerRespawns)] = true,
		[tostring(main.enum.Persistence.UntilCallerLeaves)] = true,
		[tostring(main.enum.Persistence.UntilPlayerOrCallerLeave)] = true,
	}
	local function playerOrCallerRemoving(userId, leftFromThisServer)
		local persistence = tostring(self.persistence)
		local playerLeft = (userId == self.playerUserId and validPlayerLeavingEnums[persistence])
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

	local function setupPersistenceEnum(playerInstance, playerType)
		if not main.isServer or not playerInstance then
			return
		end
		local function registerCharacter(char)
			if char then
				local humanoid = char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid")
				local function died()
					local enumItemName = ("Until%sDies"):format(playerType)
					if self.persistence == main.enum.Persistence[enumItemName] then
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
		if playerInstance then
			maid:give(playerInstance.CharacterAdded:Connect(function(char)
				local validRespawnEnumItemNames = {
					[("Until%sDies"):format(playerType)] = true,
					[("Until%sRespawns"):format(playerType)] = true,
				}
				if validRespawnEnumItemNames[main.enum.Persistence.getName(self.persistence)] then
					self:kill()
					return
				end
				registerCharacter(char)
			end))
			main.modules.Thread.spawn(registerCharacter, playerInstance.Character)
		end
	end
	setupPersistenceEnum(self.player, "Player")
	setupPersistenceEnum(self.caller, "Caller")

	-- This retrieves the agent
	local function setupAgent(agentPlayer, propertyName)
		if not agentPlayer then
			return
		end
		self[propertyName] = main.modules.PlayerUtil.getAgent(agentPlayer)
	end
	setupAgent(self.player, "playerAgent")
	setupAgent(self.caller, "callerAgent")

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

	main.modules.Thread.spawn(function()
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
					local executedOnce = false
					afterThreadConnection = thread.completed:Connect(function()
						afterThreadConnection:Disconnect()
						if not executedOnce then
							executedOnce = true
							self:execute()
						end
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
			local firstAlreadyParsedArg = parsedArgs[1]
			local i = #parsedArgs + 1
			for _, _ in pairs(command.args) do
				local iNow = i
				local argName = command.args[iNow]
				local argItem = main.modules.Parser.Args.get(argName)
				if not argItem then
					break
				end
				local argStringIndex = (firstAlreadyParsedArg and iNow - 1) or iNow
				local argString = self.args[argStringIndex] or ""
				if argItem.playerArg then
					argString = {
						[argString] = {}
					}
				end
				local promise = main.modules.Promise.defer(function(resolve)
					local returnValue = argItem:parse(argString, self.callerUserId, self.playerUserId)
					resolve(returnValue)
				end)
				table.insert(promises, promise
					:andThen(function(returnValue)
						return returnValue
					end)
					:catch(warn)
					:andThen(function(returnValue)
						local argNameLower = tostring(argName):lower()
						self.originalArgReturnValues[argNameLower] = returnValue
						self.originalArgReturnValuesFromIndex[iNow] = returnValue
						if returnValue == nil then
							local defaultValue = argItem.defaultValue
							if typeof(defaultValue) == "table" then
								defaultValue = main.modules.TableUtil.copy(argItem.defaultValue)
							end
							returnValue = defaultValue
						end
						parsedArgs[iNow] = returnValue
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
			xpcall(command.invoke, function(errorMessage)
				-- This enables the task to be cleaned up even if the command throws an error
				self:kill()
				warn(debug.traceback(tostring(errorMessage), 2))
			end, self, unpack(additional))
			finishedInvokingCommand = true
		end))
	end
	
	main.modules.Thread.spawn(function()

		-- If client task, execute with task.clientArgs
		if main.isClient then
			return invokeCommand(false, unpack(self.clientArgs))
		end

		-- If the task is player-specific (such as in ;kill foreverhd, ;kill all) find the associated player and execute the command on them
		if self.player then
			return invokeCommand(true, {self.player})
		end
		
		-- If the task has no associated player or qualifiers (such as in ;music <musicId>) then simply execute right away
		if firstArgItem and not firstArgItem.playerArg then
			return invokeCommand(true, {})
		end

		-- If the task has no associated player *but* does contain qualifiers (such as in ;globalKill all)
		local targetPlayers = (firstArgItem and firstArgItem:parse(self.qualifiers, self.callerUserId)) or {}
		if firstArgItem and firstArgItem.executeForEachPlayer then -- If the firstArg has executeForEachPlayer, convert the task into subtasks for each player returned by the qualifiers
			for i, plr in pairs(targetPlayers) do
				--self:track(main.modules.Thread.delayUntil(function() return self.filteredAllArguments == true end, function()
					local TaskService = main.services.TaskService
					local properties = TaskService.generateRecord()
					properties.callerUserId = self.callerUserId
					properties.commandName = self.commandName
					properties.args = self.args
					properties.playerUserId = plr.playerUserId
					local subtask = TaskService.createTask(false, properties)
					subtask:begin()
				--end))
			end
		else
			invokeCommand(true, {targetPlayers})
		end

	end)
	
	return Promise.defer(function(resolve)
		main.RunService.Heartbeat:Wait()
		if invokedCommand then
			self.executionThreadsCompleted:Wait()
			local humanoid = main.modules.PlayerUtil.getHumanoid(self.player)
			if not self.isDead and humanoid and humanoid.Health == 0 then
				Promise.new(function(charResolve)
					self.player.CharacterAdded:Wait()
					charResolve()
				end)
				:timeout(main.Players.RespawnTime + 1)
				:await()
			end
		end
		self.executionCompleted:Fire()
		self.executing = false
		resolve()
	end)
end

function Task:track(threadOrTween, countPropertyName, completedSignalName)
	local threadType = typeof(threadOrTween)
	local isAPromise = threadType == "table" and rawget(threadOrTween, "_unhandledRejection")
	if not isAPromise and not ((threadType == "Instance" or threadType == "table") and threadOrTween.PlaybackState) then
		error("Can only track Threads, Tweens or Promises!")
	end
	local newCountPropertyName = countPropertyName or "totalExecutionThreads"
	local newCompletedSignalName = completedSignalName or "executionThreadsCompleted"
	if not self[newCountPropertyName] then
		self[newCountPropertyName] = 0
	end
	if not self[newCompletedSignalName] then
		self[newCompletedSignalName] = self.maid:give(Signal.new())
	end
	local promiseIsStarting = isAPromise and threadOrTween:getStatus() == main.modules.Promise.Status.Started
	if isAPromise then
		if self.isDead and promiseIsStarting then
			threadOrTween:cancel()
		end
	else
		if self.isDead then
			threadOrTween:Destroy() --thread:disconnect()
			return threadOrTween
		elseif self.isPaused then
			threadOrTween:Pause() --thread:pause()
		end
		threadOrTween = self.maid:give(threadOrTween)
	end
	self[newCountPropertyName] += 1
	local function declareDead()
		local task = self
		main.modules.Thread.spawn(function()
			self[newCountPropertyName] -= 1
			if self[newCountPropertyName] == 0 and self[newCompletedSignalName] and not self.isDead then
				self[newCompletedSignalName]:Fire()
			end
			self.threads[threadOrTween] = nil
		end)
	end
	if isAPromise then
		if promiseIsStarting then
			local task = self
			local newPromise = threadOrTween:andThen(function(...)
				-- This ensures all objects within the promise are given to the task maid
				local items = {...}
				local function maybeAddItemToMaid(potentialItem)
					if typeof(potentialItem) == "table" then
						for potentialItemA, potentialItemB in pairs(potentialItem) do
							maybeAddItemToMaid(potentialItemA)
							maybeAddItemToMaid(potentialItemB)
						end
					end
					if main.modules.Maid.isValidType(potentialItem) then
						self:give(potentialItem)
					end
				end
				maybeAddItemToMaid(items)
				if task.isDead then
					self.maid:clean()
					threadOrTween:cancel()
					return
				end
				return ...
			end)
			newPromise:finally(function()
				declareDead()
			end)
			threadOrTween = newPromise
		else
			declareDead()
		end
	else
		self.threads[threadOrTween] = true
		main.modules.Thread.spawn(function()
			if not(threadOrTween.PlaybackState == main.enum.ThreadState.Completed or threadOrTween.PlaybackState == main.enum.ThreadState.Cancelled) then
				threadOrTween.Completed:Wait()
			end
			declareDead()
		end)
	end
	return threadOrTween
end

function Task:_setItemAnchored(item, bool)
	local function setAnchored(part)
		local originalValue = self.anchoredParts[part]
		if part:IsA("BasePart") then
			if (bool == true and originalValue == nil) then
				self.anchoredParts[part] = part.Anchored
				part.Anchored = true
			elseif originalValue ~= nil then
				self.anchoredParts[part] = nil
				part.Anchored = originalValue
			end
		end
		for _, child in pairs(part:GetChildren()) do
			setAnchored(child)
		end
	end
	setAnchored(item)
end

function Task:pause()
	for thread, _ in pairs(self.threads) do
		thread:Pause() --thread:pause()
	end
	for item, _ in pairs(self.trackingItems) do
		self:_setItemAnchored(item, true)
	end
	if main.isServer then
		self:pauseAllClients()
	end
	self.isPaused = true
end

function Task:resume()
	for thread, _ in pairs(self.threads) do
		thread:Play() --thread:resume()
	end
	for item, _ in pairs(self.trackingItems) do
		self:_setItemAnchored(item, false)
	end
	if main.isServer then
		self:resumeAllClients()
	end
	self.isPaused = false
end

function Task:kill()
	if self.isDead then return end
	self.isDead = true
	if self.command.revoke then
		if self.revokeArguments then
			self.command.revoke(self, unpack(self.revokeArguments))
		else
			self.command.revoke(self)
		end
	end
	self:clearBuffs()
	if main.isServer then
		self:revokeAllClients()
		if not self.modifiers.perm then --self._global == false then
			if self.cooldown > 0 then
				self.cooldownEndTime = os.clock() + self.cooldown
			end
			main.modules.Thread.delay(self.cooldown, main.services.TaskService.removeTask, self.UID)
		end
	end
	self.maid:clean()
end
Task.destroy = Task.kill
Task.Destroy = Task.kill

function Task:hijackCommand(commandName, argsTable)
	local command = main.services.CommandService.getCommand(commandName)
	if command then
		self.hijackedCommandName = command.name
		return command.invoke(self, argsTable)
	end
end

-- An abstraction of ``task.maid:give(...)``
function Task:give(item)
	if self.isDead then
		main.modules.Thread.spawn(function()
			self.maid:clean()
		end)
	end
	local function trackInstance(instance)
		self.trackingItems[instance] = true
		if instance:IsA("Tool") then
			-- It's important to unequp the humanoid and delay the destroyal of tools to give enough
			-- time for the gears effects to reset (as tools often contain Scripts and LocalScripts directly inside)
			self.maid:give(function()
				local humanoid = instance.Parent and instance.Parent:FindFirstChild("Humanoid")
				if humanoid then
					humanoid:UnequipTools()
					for _ = 1, 4 do
						main.RunService.Heartbeat:Wait()
					end
				end
				instance:Destroy()
			end)
			return
		end
		self.maid:give(function()
			self.trackingItems[instance] = nil
		end)
	end
	local itemType = typeof(item)
	-- trackInstance() tracks all relavent instances so that they can be Anchored/Unanchored when a task is paused/resumed
	if itemType == "Instance" then
		trackInstance(item)
	elseif itemType == "table" then
		-- This is to track custom objects like 'Clone' which contain the model within the table
		local MAX_DEPTH = 2
		local function trackSurfaceLevelInstances(object, depth)
			depth = depth or 0
			depth += 1
			if depth > MAX_DEPTH then
				return
			end
			local objectType = typeof(object)
			if objectType == "Instance" then
				trackInstance(object)
				return
			elseif objectType == "table" then
				for _, value in pairs(object) do
					trackSurfaceLevelInstances(value, depth)
				end
			end
		end
		trackSurfaceLevelInstances(item)
	end
	return self.maid:give(item)
end

-- An abstraction of ``task:track(main.modules.Thread.spawn(func, ...))``
function Task:spawn(func, ...)
	return self:track(main.modules.Thread.spawn(func, ...))
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

-- An abstraction of ``task:track(main.TweenService:Create(instance, tweenInfo, propertyTable))``
function Task:tween(instance, tweenInfo, propertyTable)
	return self:track(main.TweenService:Create(instance, tweenInfo, propertyTable))
end

-- An abstraction of ``self:track(main.controllers.AssetController.getClientCommandAssetOrClientPermittedAsset(self.commandName, assetName))`` (or the server equivalent)
function Task:getAsset(assetName)
	if main.isServer then
		local asset = main.services.AssetService.getCommandAssetOrServerPermittedAsset(self.commandName, assetName)
		if asset then
			self:give(asset)
		end
		-- THE SERVER IS SYNCHRONOUS THEREFORE RETURNS ASSETS IMMEDIATELY
		return asset
	end
	-- THE CLIENT IS ASSYNCHRONOUS THEREFORE RETURNS A PROMISE
	local asset = main.controllers.AssetController.getClientCommandAssetOrClientPermittedAsset(self.commandName, assetName)
	return self:track(main.controllers.AssetController.getClientCommandAssetOrClientPermittedAsset(self.commandName, assetName))
end

-- An abstraction of ``self:track(main.controllers.AssetController.getClientCommandAssetOrClientPermittedAsset(self.commandName, assetName))`` (or the server equivalent)
function Task:getAssets(...)
	if main.isServer then
		local assets = main.services.AssetService.getCommandAssetsOrServerPermittedAssets(self.commandName, ...)
		if assets then
			for _, asset in pairs(assets) do
				self:give(asset)
			end
		end
		-- THE SERVER IS SYNCHRONOUS THEREFORE RETURNS ASSETS IMMEDIATELY
		return assets
	end
	-- THE CLIENT IS ASSYNCHRONOUS THEREFORE RETURNS A PROMISE
	return self:track(main.controllers.AssetController.getClientCommandAssetsOrClientPermittedAssets(self.commandName, ...))
end

-- An abstraction of ``task.agent:buff(...)``
function Task:buffPlayer(effect, property, weight)
	local agent = self.playerAgent
	if not agent then
		error("Cannot create buff as the task has no associated player!")
	end
	local buff = agent:buff(effect, property, weight)
	table.insert(self.buffs, buff)
	return buff
end

-- An abstraction of ``task.agent:buff(...)``
function Task:buffCaller(effect, property, weight)
	local agent = self.callerAgent
	if not agent then
		-- The caller is not always in the server (for instance, for a global broadcast) so silently do nothing
		local fakeTable = {}
		setmetatable(fakeTable, {
			__index = function(table, index)
				return function() end
			end
		})
		return fakeTable
	end
	local buff = agent:buff(effect, property, weight)
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

function Task:findTag(tagName)
	local tagNameLower = tostring(tagName):lower()
	if self.tags[tagNameLower] then
		return true
	end
	return false
end

function Task:getOriginalArg(argNameOrIndex)
	local index = tonumber(argNameOrIndex)
	if index then
		return self.originalArgReturnValuesFromIndex[index]
	end
	local argItem = main.modules.Parser.Args.get(argNameOrIndex)
	local argNameLower = tostring(argNameOrIndex):lower()
	local originalValue = self.originalArgReturnValues[argNameLower]
	return originalValue
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
			commandName = self.hijackedCommandName or self.commandName,
			killAfterExecution = killAfterExecution,
			clientArgs = table.pack(...),
			playerUserId = self.playerUserId,
			player = self.player,
			callerUserId = self.callerUserId,
			caller = self.caller
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
		self:invokeClient(player, unpack(args))
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
