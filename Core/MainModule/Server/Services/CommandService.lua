-- LOCAL
local main = require(game.HDAdmin)
local System = main.modules.System
local CommandService = System.new("Commands")
local systemUser = CommandService.user
local defaultCommands = main.modules.Commands



-- BEGIN
function CommandService:begin()
	--!!
	local Parser = main.modules.Parser --!!! This is just to test the parser
	--!!

	-- Setup globals
	self.executeBatchGloballySender = main.services.GlobalService.createSender("executeBatchGlobally")
	self.executeBatchGloballyReceiver = main.services.GlobalService.createReceiver("executeBatchGlobally")
	self.executeBatchGloballyReceiver.onGlobalEvent:Connect(function(user, batch)
		CommandService.executeBatch(user, batch)
	end)

	-- Grab default commands
	for name, details in pairs(defaultCommands.dictionary) do
		CommandService.createCommand(name, details)
	end

	-- Setup auto sorters
	local records = self.records
	records:setTable("dictionary", function()
		local dictionary = {}
		for _, record in pairs(records) do
			dictionary[record.name] = record
			for _, alias in pairs(record.aliases) do
				dictionary[alias] = record
			end
		end
		return dictionary
	end, true)
	records:setTable("sortedNameAndAliasLengthArray", function()
		local array = {}
		for itemNameOrAlias, record in pairs(records:getTable("dictionary")) do
			table.insert(array, itemNameOrAlias)
		end
		table.sort(array, function(a, b) return #a > #b end)
		return array
	end)
end



-- EVENTS
CommandService.recordAdded:Connect(function(commandName, record)
	warn(("COMMAND '%s' ADDED!"):format(commandName))
end)

CommandService.recordRemoved:Connect(function(commandName)
	warn(("COMMAND '%s' REMOVED!"):format(commandName))
end)

CommandService.recordChanged:Connect(function(commandName, propertyName, propertyValue, propertyOldValue)
	warn(("BAN '%s' CHANGED %s to %s"):format(commandName, tostring(propertyName), tostring(propertyValue)))
end)



-- METHODS
function CommandService.generateRecord(key)
	return defaultCommands.dictionary[key] or {
		name = "",
		aliases	= {},
		prefixes = {},
		tags = {},
		args = {},
		invoke = function(this, caller, args)
			
		end,
		revoke = function(this, caller, args)
			
		end,
	}
end

function CommandService.createCommand(name, properties)
	local key = properties.name or name or ""
	local record = CommandService:createRecord(key, false, properties)
	return record
end

function CommandService.getCommand(name)
	return CommandService:getRecord(name)
end

function CommandService.getCommands()
	return CommandService:getRecords()
end

function CommandService.updateCommand(name, propertiesToUpdate)
	CommandService:updateRecord(name, propertiesToUpdate)
	return true
end

function CommandService.removeCommand(name)
	CommandService:removeRecord(name)
	return true
end

function CommandService.getTable(name)
	CommandService.records:getTable(name)
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
	local Modifiers = main.modules.Modifiers
	for _, item in pairs(Modifiers.sortedOrderArrayWithOnlyPreAction) do
		local continueExecution = item.preAction(user, batch)
		if not continueExecution then
			return
		end
	end
	local Args = main.modules.Args
	local isPerm = batch.modifiers.perm ~= nil and batch.modifiers.perm ~= false
	for commandName, arguments in pairs(batch.commands) do
		local command = CommandService.getCommand(commandName)
		local isCorePlayerArg = Args.playerArgsWithoutHiddenDictionary[string.lower(command.args[1])]
		local ActiveCommandService = main.services.ActiveCommandService
		local properties = ActiveCommandService.generateRecord()
		----
		properties.userId = 0 -- !!! Detemine
		properties.commandName = commandName
		properties.commandArgs = arguments or properties.commandArgs
		properties.qualifiers = batch.qualifiers or properties.qualifiers
		----
		main.services.ActiveCommandService.createActiveCommand(isPerm, properties)
	end
end

function CommandService.invokeCommand(user, commandName, ...)
	CommandService.executeBatch(user, {
		commands = {
			--commandName = args -- !!! what about qualifiers?
		}
	})
end

function CommandService.revokeCommand(user, commandName, qualifier)
	
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