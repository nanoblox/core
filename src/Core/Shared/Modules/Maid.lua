-- Maid
-- Author: Quenty
-- Source: https://github.com/Quenty/NevermoreEngine/blob/8ef4242a880c645b2f82a706e8074e74f23aab06/Modules/Shared/Events/Maid.lua
-- License: MIT (https://github.com/Quenty/NevermoreEngine/blob/version2/LICENSE.md)
-- Modified for use in Nanoblox


---	Manages the cleaning of events and other things.
-- Useful for encapsulating state and make deconstructors easy
-- @classmod Maid
-- @see Signal

local main = require(game.Nanoblox)
local Promise = main.modules.Promise


local Maid = {}
function Maid.isValidType(task)
	local taskType = typeof(task)
	if not Maid.validTypes[taskType] then
		return false, ("'%s' is an invalid task type!"):format(tostring(task))
	elseif taskType == "table" then
		for _, validMethodName in pairs(Maid.validTableMethods) do
			local method = task[validMethodName]
			if method then
				return true
			end
		end
		return false, ("'%s' does not contain a valid table method!"):format(tostring(task))
	end
	return true
end
Maid.validTypes = {
	["function"] = function(task)
		task()
	end,
	["RBXScriptConnection"] = function(task)
		task:Disconnect()
	end,
	["Instance"] = function(task)
		task:Destroy()
	end,
	["table"] = function(task)
		for _, validMethodName in pairs(Maid.validTableMethods) do
			local method = task[validMethodName]
			if method then
				method(task)
			end
		end
	end,
}
Maid.validTableMethods = {
	"Destroy",
	"destroy",
	"Cancel",
	"cancel",
	"Disconnect",
	"disconnect",
}
Maid.ClassName = "Maid"

--- Returns a new Maid object
-- @constructor Maid.new()
-- @treturn Maid
function Maid.new()
	return setmetatable({
		_tasks = {}
	}, Maid)
end

function Maid.isMaid(value)
	return type(value) == "table" and value.ClassName == "Maid"
end

--- Returns Maid[key] if not part of Maid metatable
-- @return Maid[key] value
function Maid:__index(index)
	if Maid[index] then
		return Maid[index]
	else
		return self._tasks[index]
	end
end

--- Add a task to clean up. Tasks given to a maid will be cleaned when
--  maid[index] is set to a different value.
-- @usage
-- Maid[key] = (function)         Adds a task to perform
-- Maid[key] = (event connection) Manages an event connection
-- Maid[key] = (Maid)             Maids can act as an event connection, allowing a Maid to have other maids to clean up.
-- Maid[key] = (Object)           Maids can cleanup objects with a `Destroy` method
-- Maid[key] = nil                Removes a named task. If the task is an event, it is disconnected. If it is an object,
--                                it is destroyed.
function Maid:__newindex(index, newTask)
	if Maid[index] ~= nil then
		error(("'%s' is reserved"):format(tostring(index)), 2)
	end

	local tasks = self._tasks
	local oldTask = tasks[index]

	if oldTask == newTask then
		return
	end

	tasks[index] = newTask

	if oldTask then
		local endOfTaskAction = Maid.validTypes[typeof(oldTask)]
		endOfTaskAction(oldTask)
	end
end

--- Same as indexing, but uses an incremented number as a key.
-- @param task An item to clean
-- @treturn number taskId
function Maid:giveTask(task)
	if not task then
		error("Task cannot be false or nil", 2)
	end

	local taskId = #self._tasks+1
	self[taskId] = task

	if type(task) == "table" and (not (task.Destroy or task.destroy or task.getStatus)) then
		warn("[Maid.GiveTask] - Gave table task without .Destroy\n\n" .. debug.traceback())
	end

	return taskId
end

function Maid:givePromise(promise)
	if (promise:getStatus() ~= Promise.Status.Started) then
		return promise
	end

	local newPromise = Promise.resolve(promise)
	local id = self:giveTask(newPromise)

	-- Ensure GC
	newPromise:finally(function()
		self[id] = nil
	end)

	return newPromise, id
end

function Maid:give(taskOrPromise)
	local success, errorMessage = Maid.isValidType(taskOrPromise)
	if not success then
		error(errorMessage)
	end
	local taskId, newPromise
	if type(taskOrPromise) == "table" and taskOrPromise.getStatus then
		newPromise, taskId = self:givePromise(taskOrPromise)
		taskOrPromise = newPromise
	else
		taskId = self:giveTask(taskOrPromise)
	end
	return taskOrPromise, taskId
end

--- Cleans up all tasks.
-- @alias Destroy
function Maid:doCleaning()
	local tasks = self._tasks

	-- Disconnect all events first as we know this is safe
	for index, task in pairs(tasks) do
		if typeof(task) == "RBXScriptConnection" then
			tasks[index] = nil
			task:Disconnect()
		end
	end

	-- Clear out tasks table completely, even if clean up tasks add more tasks to the maid
	local index, task = next(tasks)
	while task ~= nil do
		tasks[index] = nil
		local endOfTaskAction = Maid.validTypes[typeof(task)]
		endOfTaskAction(task)
		index, task = next(tasks)
	end
end

--- Alias for DoCleaning()
Maid.Destroy = Maid.doCleaning
Maid.destroy = Maid.doCleaning
Maid.clean = Maid.doCleaning

return Maid