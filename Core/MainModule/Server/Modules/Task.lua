-- LOCAL
local main = require(game.HDAdmin)
local Maid = main.modules.Maid
local Signal = main.modules.Signal
local Task = {}
Task.__index = Task



-- CONSTRUCTOR
function Task.new(properties)
	local self = {}
	setmetatable(self, Task)
	
	local maid = Maid.new()
	self._maid = maid
	for k,v in pairs(properties or {}) do
		self[k] = v
	end

	self.command = main.services.CommandService.getCommand(self.commandName)

	local qualifierPresent = false
	for k,v in pairs(self.qualifiers) do
		qualifierPresent = true
	end
	if not qualifierPresent then
		self.qualifiers = nil
	end
	
	return self
end



-- METHODS
function Task:execute()
	local command = self.command
	local firstCommandArg = command.args[1]

	-- Convert arg strings into arg values
	local parsedArgs = {}
	for i, argString in pairs(self.args) do
		local argName = command.args[i]
		local argItem = main.modules.Args.dictionary[argName]
		local parsedArg = argItem:parse(argString)
		table.insert(parsedArgs, parsedArg)
	end

	-- The ``this`` parameter passed through all commands
	-- This enables commands to reference their own table in additon to the task they're being called from
	local thisExecution = {
		taskUID = self.UID,
		maid = main.modules.Maid.new(),
		track = function()
			
		end
	}
	for k,v in pairs(command) do
		thisExecution[k] = v
	end

	if self.userId then
		-- User specific task
		local targetPlayer = main.Players:GetPlayerByUserId(self.userId)
		local plrParsedArg = (firstCommandArg == "player" and targetPlayer) or {targetPlayer}
		command.invoke(thisExecution, self.caller, {plrParsedArg, table.unpack(parsedArgs)})

	else
		-- Server task (which can still include players)
		local argItem = main.modules.Args.dictionary[firstCommandArg]
		if argItem.playerArg == true then
			-- Leading playerArg present
			local targets = argItem:parse(self.qualifiers)
			if firstCommandArg == "player" then
				for i, plr in pairs(targets) do
					command.invoke(thisExecution, self.caller, {plr, table.unpack(parsedArgs)})
				end
			else
				command.invoke(thisExecution, self.caller, {targets, table.unpack(parsedArgs)})
			end
		else
			-- Non-player related command, nice and easy to handle :)
			command.invoke(thisExecution, self.caller, parsedArgs)
		end
	end

	--[[ filter thingy mbobies
	local ChatService = main.services.ChatService
	local messageObject = ChatService.getTextObject(message, sender.UserId)
	if messageObject then
		local filteredMessage = getFilteredMessage(messageObject, recipient.UserId)
		sendMessageEvent:FireClient(recipient, sender, message)
	end
	--]]
end

function Task:destroy()
	self._maid:clean()
end



return Task