local main = require(game.Nanoblox)
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
		description	= "Permanently saves the task. This means in addition to the initial execution, the command will be executed whenever a server starts, or if player specific, every time the player joins a server.",
		preAction = function(user, batch)
			local modifiers = batch.modifiers
			local oldGlobal = modifiers.global
			if oldGlobal then
				-- Its important to ignore the global modifier in this situation as setting Task to
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
		description	= "Broadcasts the task to all servers.",
		preAction = function(caller, batch)
			local CommandService = main.services.CommandService
			local modifiers = batch.modifiers
			local oldGlobal = modifiers.global
			local callerCopy = {}
			callerCopy.name = caller.name
			callerCopy.userId = caller.userId
			callerCopy.player = {
				Name = caller.name,
				UserId = caller.userId,
			}
			modifiers.global = nil
			modifiers.wasGlobal = oldGlobal
			CommandService.executeBatchGloballySender:fireAllServers(callerCopy, batch)
			return false
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "undo",
		aliases = {"un", "u-", "revoke"},
		order = 4,
		description	= "Revokes all tasks that match the given command name(s) (and associated player targets if specified). To revoke a task across all servers, the 'global' modifier must be included.",
		preAction = function()
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "preview",
		aliases = {"pr-"},
		order = 5,
		description	= "Displays a menu that previews the command instead of executing it.",
		preAction = function()
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "delay",
		aliases = {"d-"},
		order = 6,
		description	= "Waits x amount of time before executing the command. Time can be represented in seconds as 's', minutes as 'm', hours as 'h', days as 'd', weeks as 'w' and years as 'y'. Example: ``;delay(3s)kill all``.",
		action = function(task, values)
			local timeDelay = table.unpack(values)
			local seconds = main.modules.DataUtil.convertTimeStringToSeconds(timeDelay)
			local thread = main.modules.Thread.delay(seconds, task.execute, task)
			return thread
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "epoch",
		aliases = {"e-"},
		order = 7,
		description	= "Waits until the given epoch time before executing. If the epoch time has already passed, the command will be executed right away. Combine with 'global' and 'perm' for a permanent game effect. Example: ``;globalPermEpoch(3124224000)message(green) Happy new year!``",
		action = function(task, values)
			local executionTime = table.unpack(values)
			local timeNow = os.time()
			local newExecutionTime = tonumber(executionTime) or timeNow + 1
			local seconds = newExecutionTime - timeNow
			local thread = main.modules.Thread.delay(seconds, task.execute, task)
			return thread
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "loop",
		aliases = {"repeat", "l-"},
		order = 8,
		description	= "Repeats a command for x iterations every y time delay. If not specified, x defaults to ∞ and y to 1s. Time can be represented in seconds as 's', minutes as 'm', hours as 'h', days as 'd', weeks as 'w' and years as 'y'. Example: ``;loop(50,1s)jump me``.",
		action = function(task, values)
			local iterations, interval = table.unpack(values)
			local ITERATION_LIMIT = 10000
			local MINIMUM_INTERVAL = 0.1
			local newInterations = tonumber(iterations) or ITERATION_LIMIT
			if newInterations > ITERATION_LIMIT then
				newInterations = ITERATION_LIMIT
			end
			local newInterval = tonumber(interval) or MINIMUM_INTERVAL
			if newInterval < MINIMUM_INTERVAL then
				newInterval = MINIMUM_INTERVAL
			end
			local thread = main.modules.Thread.loopFor(newInterval, newInterations, task.execute, task)
			return thread
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "spawn",
		aliases = {"s-"},
		order = 9,
		description	= "Executes the command every time the given player(s) respawn (in addition to the initial execution). This modifier only works for commands with player-related arguments.",
		action = function(task)
			-- have this wrapped in a thread and yield until the player leaves the game
			-- call :execute right away, then whenever the player respawns also execute
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "expire",
		aliases = {"x-", "until"},
		order = 10,
		description	= "Revokes the command after the given time. Time can be represented in seconds as 's', minutes as 'm', hours as 'h', days as 'd', weeks as 'w' and years as 'y'. Example: ``;expire(2m30s)mute player``.",
		action = function(task, values)
			local timeDelay = table.unpack(values)
			local seconds = main.modules.DataUtil.convertTimeStringToSeconds(timeDelay)
			task:execute()
			local thread = main.modules.Thread.delay(seconds, task.kill, task)
			return thread
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