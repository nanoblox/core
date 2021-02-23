-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local TaskService = System.new("Tasks")
TaskService.remotes = {
	invokeClientCommand = main.modules.Remote.new("invokeClientCommand"),
	revokeClientCommand = main.modules.Remote.new("revokeClientCommand"),
	callClientTaskMethod = main.modules.Remote.new("callClientTaskMethod"),
	replicationRequest = main.modules.Remote.new("replicationRequest", 12, 1, 200),
	replicateClientCommand = main.modules.Remote.new("replicateClientCommand"),
}
local systemUser = TaskService.user
local tasks = {}
local Task = main.modules.Task



-- START
function TaskService.start()
	TaskService.replicationRequest.onServerEvent:Connect(function(player, taskUID, targetPool, packedArgs, packedData)
		local task = TaskService.getTask(taskUID)
		local clockTime = os.clock()
		local errorMessage
		local targetPoolName = main.enum.TargetPool.getName(targetPool)
		if not task then
			errorMessage = "Replication blocked: Task not found!"
		elseif task.caller.userId ~= player.UserId then
			errorMessage = "Replication blocked: Requester's UserId does not match caller's UserId!"
		elseif not task.command.preReplication then
			errorMessage = "Replication blocked: ServerCommand:PreReplication(task, targetPool, packedData) must be specified!"
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
				task.replicationsThisSecond = 0
			end
			local success, blockMessage = task.command:preReplication(task, targetPool, packedData)
			if not success then
				if not blockMessage then
					blockMessage = ("Unspecified command rejection for '%s'."):format(task.command.name)
				end
				errorMessage = ("Replication blocked: %s"):format(tostring(blockMessage))
			end
		end
		if not errorMessage then
			local success, playersArrayOrErrorMessage = pcall(function() return main.enum.TargetPool.getProperty(targetPoolName)(table.unpack(packedArgs)) end)
			if not success then
				errorMessage = playersArrayOrErrorMessage
			else
				for _, plr in pairs(playersArrayOrErrorMessage) do
					main.replicateClientCommand:fireClient(plr, packedData)
				end
				task.totalReplications += 1
				task.replicationsThisSecond += 1
			end
		end
		if errorMessage then
			--!!!notice here
			return
		end
	end)
end



-- EVENTS
local commandNameToTask = main.modules.State.new() -- This allows for super quick retrieval of a group of tasks with the same commandName
local targetUserIdToTaskGroup = main.modules.State.new() -- This allows for super quick retrieval of a group of tasks with the same targetUserId
TaskService.recordAdded:Connect(function(UID, record)
	--warn(("TASK '%s' ADDED!"):format(UID))
	local task = Task.new(record)
	task.UID = UID
	tasks[UID] = task
	task:begin()
	if task.targetUserId then
		targetUserIdToTaskGroup:getOrSetup(task.targetUserId, task.commandName):set(UID, task)  -- This allows for super quick retrieval of a group of tasks with the same targetUserId
	end
	commandNameToTask:getOrSetup(task.commandName):set(UID, task)
end)

TaskService.recordRemoved:Connect(function(UID)
	--warn(("TASK '%s' REMOVED!"):format(UID))
	local task = tasks[UID]
	if task then
		task:destroy()
		task[UID] = nil
	end
	local userTaskCommandGroup = targetUserIdToTaskGroup:find(task.targetUserId, task.commandName)
	if userTaskCommandGroup then
		userTaskCommandGroup:set(UID, nil)
	end
	local taskCommandGroup = commandNameToTask:find(task.commandName)
	if taskCommandGroup then
		taskCommandGroup:set(UID, nil)
	end
end)

TaskService.recordChanged:Connect(function(UID, propertyName, propertyValue, propertyOldValue)
	--warn(("TASK '%s' CHANGED %s to %s"):format(UID, tostring(propertyName), tostring(propertyValue)))
	local task = tasks[UID]
	if task then
		task[propertyName] = propertyValue
	end
end)



-- METHODS
function TaskService.generateRecord(key)
	return {
		executionTime = os.time(),
		executionOffset = os.time() - tick(),
		caller = nil,
		commandName = "",
		args = {},
		qualifiers = {},
		targetUserId = nil,
	}
end

function TaskService.createTask(isGlobal, properties)
	local key = (properties and properties.UID) or main.modules.DataUtil.generateUID(10)
	properties.UID = key
	---
	local commandName = properties.commandName
	local command = main.services.CommandService.getCommand(commandName)
	if not command then
		return false
	end
	local runningTasks = TaskService.getTasksWithCommandNameAndOptionalTargetUserId(commandName, properties.targetUserId)
	if command.revokeRepeats then
		for _, task in pairs(runningTasks) do
			task:kill()
		end
	else
		local preventRepeats = command.preventRepeats
		if preventRepeats == main.enum.TriStateSetting.Default then
			preventRepeats = main.services.SettingService.getGroup("System").preventRepeatCommands
		end
		if preventRepeats and #runningTasks > 0 then
			warn("Wait until command '%s' has finished before using again!") --!!!notice
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

function TaskService.getTasksWithTargetUserId(targetUserId)
	local tasksArray = {}
	local userTaskCommandGroups = targetUserIdToTaskGroup:find(targetUserId)
	if userTaskCommandGroups then
		for _, groupOfTasks in pairs(userTaskCommandGroups) do
			for _, task in pairs(groupOfTasks) do
				table.insert(tasksArray, task)
			end
		end
	end
	return tasksArray
end

function TaskService.getTasksWithCommandNameAndTargetUserId(commandName, targetUserId)
	local tasksArray = {}
	local userTaskCommandGroup = targetUserIdToTaskGroup:find(targetUserId, commandName)
	if userTaskCommandGroup then
		for _, task in pairs(userTaskCommandGroup) do
			table.insert(tasksArray, task)
		end
	end
	return tasksArray
end

function TaskService.getTasksWithCommandNameAndOptionalTargetUserId(commandName, optionalTargetUserId)
	local tasksArray = (optionalTargetUserId and TaskService.getTasksWithCommandNameAndTargetUserId(commandName, optionalTargetUserId)) or TaskService.getTasksWithCommandName(commandName)
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

function TaskService.removeTasksWithTargetUserId(targetUserId)
	local tasksArray = TaskService.getTasksWithTargetUserId(targetUserId)
	for _, task in pairs(tasksArray) do
		TaskService.removeTask(task.UID)
	end
end

function TaskService.removeTasksWithCommandNameAndTargetUserId(commandName, targetUserId)
	local tasksArray = TaskService.getTasksWithCommandNameAndTargetUserId(commandName, targetUserId)
	for _, task in pairs(tasksArray) do
		TaskService.removeTask(task.UID)
	end
end



return TaskService