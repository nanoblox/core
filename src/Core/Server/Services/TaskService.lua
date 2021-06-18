-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local TaskService = System.new("Tasks")
TaskService.remotes = {}
local tasks = {}
local Task = main.modules.Task
local Signal = main.modules.Signal.new()



-- START
function TaskService.start()

	-- REMOTES
	local invokeClientCommand = main.modules.Remote.new("invokeClientCommand")
    TaskService.remotes.invokeClientCommand = invokeClientCommand

	local revokeClientCommand = main.modules.Remote.new("revokeClientCommand")
    TaskService.remotes.revokeClientCommand = revokeClientCommand

	local callClientTaskMethod = main.modules.Remote.new("callClientTaskMethod")
    TaskService.remotes.callClientTaskMethod = callClientTaskMethod

	local replicationRequest = main.modules.Remote.new("replicationRequest")
	replicationRequest.onServerEvent:Connect(function(player, taskUID, targetPool, packedArgs, packedData)
		local task = TaskService.getTask(taskUID)
		local clockTime = os.clock()
		local errorMessage
		local targetPoolName = main.enum.TargetPool.getName(targetPool)
		if not task then
			errorMessage = "Replication blocked: Task not found!"
		elseif task.callerUserId ~= player.UserId then
			errorMessage = "Replication blocked: Requester's UserId does not match caller's UserId!"
		elseif not task.command.preReplication then
			errorMessage = "Replication blocked: ServerCommand.preReplication(task, targetPool, packedData) must be specified!"
		elseif not targetPoolName then
			errorMessage = "Replication blocked: Invalid argument, 'targetPool' must be a TargetPool enum!"
		elseif typeof(packedArgs) ~= "table" then
			errorMessage = "Replication blocked: Invalid argument, 'packedArgs' must be a table!"
		elseif typeof(packedData) ~= "table" then
			errorMessage = "Replication blocked: Invalid argument, 'packedData' must be a table!"
		end
		if not errorMessage then
			if clockTime >= (task._nextReplicationsThisSecondRefresh or 0) then
				task._nextReplicationsThisSecondRefresh = clockTime + 1
				task.replicationRequestsThisSecond = 1
			end
			local success, blockMessage = task.command.preReplication(task, targetPool, packedData)
			if not success then
				if not blockMessage then
					blockMessage = ("Unspecified command rejection for '%s'."):format(task.command.name)
				end
				errorMessage = ("Replication blocked: %s"):format(tostring(blockMessage))
			end
		end
		if not errorMessage then
			local success, playersArrayOrErrorMessage = pcall(function() return main.enum.TargetPool.getProperty(targetPoolName)(unpack(packedArgs)) end)
			if not success then
				errorMessage = playersArrayOrErrorMessage
			else
				for _, plr in pairs(playersArrayOrErrorMessage) do
					TaskService.remotes.replicateClientCommand:fireClient(plr, task.UID, packedData)
				end
				task.totalReplicationRequests += 1
				task.replicationRequestsThisSecond += 1
			end
		end
		if errorMessage then
			warn(errorMessage)
			--!!!notice here player or caller??, probably player
			return
		end
	end)
	TaskService.remotes.replicationRequest = replicationRequest

	local replicateClientCommand = main.modules.Remote.new("replicateClientCommand")
    TaskService.remotes.replicateClientCommand = replicateClientCommand


	-- GLOBALS
	local callerLeftSender = main.services.GlobalService.createSender("callerLeft")
	local callerLeftReceiver = main.services.GlobalService.createReceiver("callerLeft")
	callerLeftReceiver.onGlobalEvent:Connect(function(callerUserId)
		local tasksNow = TaskService.getTasks()
		for _, task in pairs(tasksNow) do
			if task.callerUserId == callerUserId and not task.isDead then
				task.callerLeft:Fire()
			end
		end
	end)
	TaskService.callerLeftSender = callerLeftSender
	TaskService.callerLeftReceiver = callerLeftReceiver

end



-- EVENTS
local commandNameToTask = main.modules.State.new() -- This allows for super quick retrieval of a group of tasks with the same commandName
local playerUserIdToTaskGroup = main.modules.State.new() -- This allows for super quick retrieval of a group of tasks with the same playerUserId

TaskService.taskAdded = Signal.new()
TaskService.taskChanged = Signal.new()
TaskService.taskRemoved = Signal.new()

TaskService.recordAdded:Connect(function(UID, record)
	--warn(("TASK '%s' ADDED!"):format(UID))
	local task = Task.new(record)
	task.UID = UID
	tasks[UID] = task
	task:begin()
	if task.playerUserId then
		playerUserIdToTaskGroup:getOrSetup(task.playerUserId, task.commandNameLower):set(UID, task)  -- This allows for super quick retrieval of a group of tasks with the same playerUserId
	end
	commandNameToTask:getOrSetup(task.commandNameLower):set(UID, task)
	TaskService.taskAdded:Fire(task)
end)

TaskService.recordRemoved:Connect(function(UID)
	--warn(("TASK '%s' REMOVED!"):format(UID))
	local task = tasks[UID]
	if task then
		task:destroy()
		task[UID] = nil
	end
	local userTaskCommandGroup = playerUserIdToTaskGroup:find(task.playerUserId, task.commandNameLower)
	if userTaskCommandGroup then
		userTaskCommandGroup:set(UID, nil)
	end
	local taskCommandGroup = commandNameToTask:find(task.commandNameLower)
	if taskCommandGroup then
		taskCommandGroup:set(UID, nil)
	end
	TaskService.taskRemoved:Fire(task)
end)

TaskService.recordChanged:Connect(function(UID, propertyName, propertyValue, propertyOldValue)
	--warn(("TASK '%s' CHANGED %s to %s"):format(UID, tostring(propertyName), tostring(propertyValue)))
	local task = tasks[UID]
	if task then
		task[propertyName] = propertyValue
	end
	TaskService.taskChanged:Fire(task, propertyName, propertyValue, propertyOldValue)
end)



-- METHODS
function TaskService.generateRecord(key)
	return {
		executionTime = os.time(),
		executionOffset = os.time() - tick(),
		callerUserId = nil,
		commandName = "",
		args = {},
		qualifiers = {},
		playerUserId = nil,
	}
end

function TaskService.createTask(isGlobal, properties)
	local key = (properties and properties.UID) or main.modules.DataUtil.generateUID(10)
	properties.UID = key
	---
	local command = main.services.CommandService.getCommand(properties.commandName)
	if not command then
		return false
	end
	local commandNameLower = string.lower(properties.commandName)
	properties.commandNameLower = commandNameLower
	local runningTasks = TaskService.getTasksWithCommandNameAndOptionalPlayerUserId(commandNameLower, properties.playerUserId)
	if command.revokeRepeats then
		for _, task in pairs(runningTasks) do
			task.cooldown = 0
			task:kill()
		end
	else
		local preventRepeats = command.preventRepeats
		if preventRepeats == main.enum.TriStateSetting.Default then
			preventRepeats = main.services.SettingService.getGroup("System").preventRepeatCommands
		end
		if preventRepeats and #runningTasks > 0 then
			local firstRunningTask = runningTasks[1]
			local taskCooldownEndTime = firstRunningTask.cooldownEndTime
			local additionalUserMessage = ""
			local associatedPlayer = firstRunningTask.player
			if associatedPlayer then
				additionalUserMessage = (" on '%s' (@%s)"):format(associatedPlayer.DisplayName, associatedPlayer.Name)
			end
			if taskCooldownEndTime then
				local remainingTime = (math.ceil((taskCooldownEndTime-os.clock())*100))/100
				warn(("Wait %s seconds until command '%s' has cooldown before using again%s!"):format(remainingTime, command.name, additionalUserMessage)) --!!!notice
				return
			end
			warn(("Wait until command '%s' has finished before using again%s!"):format(command.name, additionalUserMessage)) --!!!notice
			return
		end
	end
	---
	TaskService:createRecord(key, isGlobal, properties)
	local task = TaskService.getTask(key)
	return task
end

function TaskService.getTask(UID)
	local task = tasks[UID]
	if not task then
		return false
	end
	return task
end

function TaskService.getTasks()
	local allTasks = {}
	for name, task in pairs(tasks) do
		table.insert(allTasks, task)
	end
	return allTasks
end

function TaskService.getTasksWithCommandName(commandName)
	local tasksArray = {}
	local taskCommandGroup = commandNameToTask:find(commandName)
	if taskCommandGroup then
		for _, task in pairs(taskCommandGroup) do
			table.insert(tasksArray, task)
		end
	end
	return tasksArray
end

function TaskService.getTasksWithPlayerUserId(playerUserId)
	local tasksArray = {}
	local userTaskCommandGroups = playerUserIdToTaskGroup:find(playerUserId)
	if userTaskCommandGroups then
		for _, groupOfTasks in pairs(userTaskCommandGroups) do
			for _, task in pairs(groupOfTasks) do
				table.insert(tasksArray, task)
			end
		end
	end
	return tasksArray
end

function TaskService.getTasksWithCommandNameAndPlayerUserId(commandName, playerUserId)
	local tasksArray = {}
	local userTaskCommandGroup = playerUserIdToTaskGroup:find(playerUserId, commandName)
	if userTaskCommandGroup then
		for _, task in pairs(userTaskCommandGroup) do
			table.insert(tasksArray, task)
		end
	end
	return tasksArray
end

function TaskService.getTasksWithCommandNameAndOptionalPlayerUserId(commandName, optionalPlayerUserId)
	local tasksArray = (optionalPlayerUserId and TaskService.getTasksWithCommandNameAndPlayerUserId(commandName, optionalPlayerUserId)) or TaskService.getTasksWithCommandName(commandName)
	return tasksArray
end

function TaskService.updateTask(UID, propertiesToUpdate)
	local task = TaskService.getTask(UID)
	assert(task, ("task '%s' not found!"):format(tostring(UID)))
	TaskService:updateRecord(UID, propertiesToUpdate)
	return true
end

function TaskService.removeTask(UID)
	local task = TaskService.getTask(UID)
	assert(task, ("task '%s' not found!"):format(tostring(UID)))
	TaskService:removeRecord(UID)
	return true
end

function TaskService.removeTasksWithCommandName(commandName)
	local tasksArray = TaskService.getTasksWithCommandName(commandName)
	for _, task in pairs(tasksArray) do
		TaskService.removeTask(task.UID)
	end
end

function TaskService.removeTasksWithPlayerUserId(playerUserId)
	local tasksArray = TaskService.getTasksWithPlayerUserId(playerUserId)
	for _, task in pairs(tasksArray) do
		TaskService.removeTask(task.UID)
	end
end

function TaskService.removeTasksWithCommandNameAndPlayerUserId(commandName, playerUserId)
	local tasksArray = TaskService.getTasksWithCommandNameAndPlayerUserId(commandName, playerUserId)
	for _, task in pairs(tasksArray) do
		TaskService.removeTask(task.UID)
	end
end

function TaskService.removeTasksWithCommandNameAndOptionalPlayerUserId(commandName, optionalPlayerUserId)
	local tasksArray = TaskService.getTasksWithCommandNameAndOptionalPlayerUserId(commandName, optionalPlayerUserId)
	for _, task in pairs(tasksArray) do
		TaskService.removeTask(task.UID)
	end
end



return TaskService