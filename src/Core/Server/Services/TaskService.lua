-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local TaskService = System.new("Tasks")
local systemUser = TaskService.user
local tasks = {}
local Task = main.modules.Task



-- BEGIN
function TaskService.begin()
	
end



-- EVENTS
TaskService.recordAdded:Connect(function(UID, record)
	--warn(("TASK '%s' ADDED!"):format(UID))
	local task = Task.new(record)
	task.UID = UID
	tasks[UID] = task
end)

TaskService.recordRemoved:Connect(function(UID)
	--warn(("TASK '%s' REMOVED!"):format(UID))
	local task = tasks[UID]
	if task then
		task:destroy()
		task[UID] = nil
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
		userId = 0,
	}
end

function TaskService.createTask(isGlobal, properties)
	local key = (properties and properties.UID) or main.modules.DataUtil.generateUID(10)
	TaskService:createRecord(key, isGlobal, properties)
	local task = TaskService.getRole(key)
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
	
end

function TaskService.getTasksWithUserId(userId)
	
end

function TaskService.getTasksWithCommandNameAndUserId(commandName, userId)
	
end

function TaskService.updateTask(UID, propertiesToUpdate)
	local task = TaskService.getRole(UID)
	assert(task, ("task '%s' not found!"):format(tostring(UID)))
	TaskService:updateRecord(UID, propertiesToUpdate)
	return true
end

function TaskService.removeTask(UID)
	local task = TaskService.getRole(UID)
	assert(task, ("task '%s' not found!"):format(tostring(UID)))
	TaskService:removeRecord(UID)
	return true
end



return TaskService