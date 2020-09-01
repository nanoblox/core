-- LOCAL
local main = require(game.HDAdmin)
local System = main.modules.System
local CommandService = System.new("Commands")
local systemUser = CommandService.user
local Command = main.modules.Command
local defaultCommands = main.modules.Commands
local commands = {}



-- EVENTS
CommandService.recordAdded:Connect(function(commandName, record)
	local command = Command.new(record)
	command.name = commandName
	commands[commandName] = command
end)

CommandService.recordRemoved:Connect(function(commandName)
	local command = commands[commandName]
	if command then
		command:destroy()
		commands[commandName] = nil
	end
end)

CommandService.recordChanged:Connect(function(commandName, propertyName, propertyValue, propertyOldValue)
	local command = commands[commandName]
	if command then
		command[propertyName] = propertyValue
	end
end)



-- METHODS
function CommandService.generateRecord(key)
	return defaultCommands.dictionary[key] or {
		name = "",
		aliases	= {},
		prefixes = {},
		tags = {},
		args = {},
		invoke = function(self, caller, args)
			
		end,
		revoke = function(self, caller, args)
			
		end,
	}
end

function CommandService:createCommand(isGlobal, name, properties)
	local key = properties.name or name or ""
	CommandService:createRecord(key, isGlobal, properties)
	local command = CommandService:getCommand(key)
	return command
end

function CommandService:getCommand(name)
	return commands[name]
end

function CommandService:getAllCommands()
	local allCommands = {}
	for name, command in pairs(commands) do
		table.insert(allCommands, command)
	end
	return allCommands
end

function CommandService:updateCommand(name, propertiesToUpdate)
	local command = CommandService:getCommand(name)
	assert(command, ("command '%s' not found!"):format(name))
	CommandService:updateRecord(name, propertiesToUpdate)
	return true
end

function CommandService:removeCommand(name)
	local command = CommandService:getCommand(name)
	assert(command, ("command '%s' not found!"):format(name))
	CommandService:removeRecord(name)
	return true
end



return CommandService