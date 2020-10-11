local main = require(game.HDAdmin)
local Modifiers = {}



-- ARRAY
Modifiers.array = {
	
	-----------------------------------
	{
		name = "random",
		aliases = {"r-"},
		order = 1,
		description	= "Randomly selects a command within a batch. All other commands are discarded.",
		preAction = function(user, batch)
			local commands = batch.commands
			if #commands > 1 then
				local randomIndex = math.random(1, #commands)
				local selectedItem = commands[randomIndex]
				commands = {selectedItem}
				batch.commands = commands
			end
			return true
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "perm",
		aliases = {"p-"},
		order = 2,
		description	= "Permanently applies the command. This means in addition to the initial execution, the command will be executed whenever a server starts, or if player specific, every time the player joins a server.",
		preAction = function(user, batch)
			local modifiers = batch.modifiers
			local oldGlobal = modifiers.global
			if oldGlobal then
				-- Its important to ignore the global modifier in this situation as setting an ActiveCommand to
				-- perm storage achieves the same effect. Merging both together however would create
				-- a vicious infinite cycle 
				modifiers.global = nil
				modifiers.wasGlobal = oldGlobal
			end
			return true
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "global",
		aliases = {"g-"},
		order = 3,
		description	= "Broadcasts the batch to all servers.",
		preAction = function(user, batch)
			local CommandService = main.services.CommandService
			local modifiers = batch.modifiers
			local oldGlobal = modifiers.global
			local userCopy = {}
			userCopy.name = user.name
			userCopy.userId = user.userId
			userCopy.player = {
				Name = user.name,
				UserId = user.userId,
			}
			modifiers.global = nil
			modifiers.wasGlobal = oldGlobal
			CommandService.executeBatchGloballySender:fireAllServers(userCopy, batch)
			return false
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "undo",
		aliases = {"un", "u-", "revoke"},
		order = 4,
		description	= "Revokes all active commands that match the given command name(s) (and associated player targets if specified). To revoke an active command across all servers, the 'global' modifier must also be included.",
		action = function()
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "preview",
		aliases = {"pr-"},
		order = 5,
		description	= "Displays a menu that previews the command before execution, including any given arguments.",
		action = function()
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "delay",
		aliases = {"d-"},
		order = 6,
		description	= "Waits x amount of seconds before executing the command. Example: ``;delay(3)kill all``",
		action = function(delayAmount)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "epoch",
		aliases = {"e-"},
		order = 7,
		description	= "Waits until the given epoch time before executing. If the epoch time has already passed, the command will be executed right away. Combine with 'global' and 'perm' for a permanent game effect. Example: ``;globalPermEpoch(3124224000)message(green) Happy new year!``",
		action = function(executionTime)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "loop",
		aliases = {"repeat", "l-"},
		order = 8,
		description	= "Repeats a command for x iterations every y delay. If not specified, x defaults to ∞ and y to 1. Example: ``;loop(50,1)jump me``",
		action = function(iterations, reiterateDelayAmount)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "spawn",
		aliases = {"s-"},
		order = 9,
		description	= "Executes the command every time the given player(s) respawn (in addition to the initial execution). This modifier only works for commands with player-related arguments.",
		action = function()
			
		end,
	};
	
	
	
	-----------------------------------
	
};



-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Modifiers.dictionary.MODIFIER_NAME`` to return its item
Modifiers.dictionary = {}
for _, item in pairs(Modifiers.array) do
	Modifiers.dictionary[item.name] = item
	for _, alias in pairs(item.aliases) do
		Modifiers.dictionary[alias] = item
	end
end



-- SORTED ARRAY(S)
local copy = main.modules.TableUtil.copy
Modifiers.sortedNameAndAliasLengthArray = {}
for itemNameOrAlias, item in pairs(Modifiers.dictionary) do
	table.insert(Modifiers.sortedNameAndAliasLengthArray, itemNameOrAlias)
end
table.sort(Modifiers.sortedNameAndAliasLengthArray, function(a, b) return #a > #b end)

Modifiers.sortedOrderArray = copy(Modifiers.array)
table.sort(Modifiers.sortedOrderArray, function(a, b) return a.order > b.order end)

Modifiers.sortedOrderArrayWithOnlyPreAction = {}
Modifiers.sortedOrderArrayWithOnlyAction = {}
for _, item in pairs(Modifiers.sortedOrderArray) do
	if item.preAction then
		table.insert(Modifiers.sortedOrderArrayWithOnlyPreAction, item)
	end
	if item.action then
		table.insert(Modifiers.sortedOrderArrayWithOnlyAction, item)
	end
end



return Modifiers