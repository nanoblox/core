-- LOCAL
local main = require(game.HDAdmin)
local System = main.modules.System
local CommandService = System.new("Commands")
local systemUser = CommandService.user
local Command = main.modules.Command
local defaultCommands = main.modules.Commands
local commands = {}



-- BEGIN
function CommandService:begin()
	--!!
	local Parser = main.modules.Parser --!!! This is just to test the parser
	--!!
	-- Grab default commands
	local Commands = main.modules.Commands
	for name, details in pairs(Commands.dictionary) do
		CommandService:createCommand(false, name, details)
	end
	-- Setup auto sorters
	self.records:setTable("array", function(mirrorTable)
		local recordsArray = {}
		for key, record in pairs(mirrorTable) do
			table.insert(recordsArray, record)
		end
		return recordsArray
	end)
	self.records:setTable("sortedNameLengthArray", function(mirrorTable)
		table.sort(mirrorTable, function(a, b) print(a.name.." > ".. b.name) return #a.name > #b.name end)
		return mirrorTable
	end, self.records:getTable("array"))
end



-- EVENTS
CommandService.recordAdded:Connect(function(commandName, record)
	warn(("COMMAND '%s' ADDED!"):format(commandName))
	local command = Command.new(record)
	command.name = commandName
	commands[commandName] = command
end)

CommandService.recordRemoved:Connect(function(commandName)
	warn(("COMMAND '%s' REMOVED!"):format(commandName))
	local command = commands[commandName]
	if command then
		command:destroy()
		commands[commandName] = nil
	end
end)

CommandService.recordChanged:Connect(function(commandName, propertyName, propertyValue, propertyOldValue)
	warn(("BAN '%s' CHANGED %s to %s"):format(commandName, tostring(propertyName), tostring(propertyValue)))
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

function CommandService.chatCommand(user, message)
	print(user.name, "chatted: ", message)
	local batches = main.modules.Parser.parseMessage(message)
	if type(batches) == "table" then
		for i, batch in pairs(batches) do
			local approved, noticeDetails = CommandService.verifyBatch(user, batch)
			if approved then
				CommandService.executeBatch(user, batch)
			end
			for _, detail in pairs(noticeDetails) do
				local method = main.services.MessageService[detail[1]]
				method(user.player, detail[2])
			end
		end
	end
end

function CommandService.verifyBatch(user, batch)
	local approved = true
	local details = {}

	local jobId = batch.jobId
	local batchCommands = batch.commands
	local modifiers = batch.modifiers
	local qualifiers = batch.qualifiers
	
	-- Global
	if modifiers.global then
		table.insert(details, {"notice", {
			text = "Executing global command...",
			error = true,
		}})
	end

	-- !!! Error example
	table.insert(details, {"notice", {
		text = "You do not have permission to do that!",
		error = true,
	}})

	return approved, details
end

function CommandService.executeBatch(user, batch)
	
end


--[[

local batch = {
	jobId = game.JobId;
	commands = {
		noobify = {"red"},
		goldify = {"red"},
	},
	modifiers = {
		global = {},
		random = {},
	},
	qualifiers = {
		random = {"ben", "matt", "sam"},
		me = true,
		nonadmins = true,
	},
}

]]



return CommandService