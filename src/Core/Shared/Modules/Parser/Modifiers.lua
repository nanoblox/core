-- Modifiers are items that can be applied to statements to enhance a commands default behaviour
-- They are split into two groups:
-- 		1. PreAction Modifiers - these execute before a task is created and can block the task being created entirely
--		2. Action Modifiers - these execute while a task is running and can extend the longevity of the task

local main = require(game.Nanoblox)
local Modifiers = {}

-- ARRAY
Modifiers.array = {

	-----------------------------------
	{
		name = "preview",
		aliases = {"prev"},
		order = 1,
		description = "Displays a menu that previews the command instead of executing it.",
		preAction = function(callerUserId, statement)
			local caller = main.Players:GetPlayerByUserId(callerUserId)
			if caller then
				--!!! remove this
				warn("Preview: ", statement)
				main.services.CommandService.remotes.previewCommand:fireClient(caller, statement)
			end
			return false
		end,
	},

	-----------------------------------
	{
		name = "random",
		aliases = { "rand" },
		order = 2,
		description = "Randomly selects a command within a statement. All other commands are discarded.",
		preAction = function(_, statement)
			local commands = statement.commands
			if #commands > 1 then
				local randomIndex = math.random(1, #commands)
				local selectedItem = commands[randomIndex]
				commands = { selectedItem }
				statement.commands = commands
			end
			return true
		end,
	},

	-----------------------------------
	{
		name = "perm",
		aliases = {},
		order = 3,
		description = "Permanently saves the task. This means in addition to the initial execution, the command will be executed whenever a server starts, or if player specific, every time the player joins a server.",
		preAction = function(_, statement)
			local modifiers = statement.modifiers
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
	},

	-----------------------------------
	{
		name = "global",
		aliases = {},
		order = 4,
		description = "Broadcasts the task to all servers.",
		preAction = function(callerUserId, statement)
			local CommandService = main.services.CommandService
			local modifiers = statement.modifiers
			local oldGlobal = modifiers.global
			modifiers.global = nil
			modifiers.wasGlobal = oldGlobal
			CommandService.executeStatementGloballySender:fireAllServers(callerUserId, statement)
			return false
		end,
	},

	-----------------------------------
	{
		name = "undo",
		aliases = { "un", "revoke" },
		order = 5,
		description = "Revokes all tasks that match the given command name(s) (and associated player targets if specified). To revoke a task across all servers, the 'global' modifier must be included.",
		preAction = function(callerUserId, statement)
			local Args = main.modules.Parser.Args
			for commandName, _ in pairs(statement.commands) do
				local command = main.services.CommandService.getCommand(commandName)
				if command then
					local firstCommandArg = command.args[1]
					local firstArgItem = Args.get(firstCommandArg)
					if firstArgItem.playerArg and firstArgItem.executeForEachPlayer then
						local targets = Args.get("player"):parse(statement.qualifiers, callerUserId)
						for _, plr in pairs(targets) do
							main.services.TaskService.removeTasksWithCommandNameAndPlayerUserId(commandName, plr.UserId)
						end
					else
						main.services.TaskService.removeTasksWithCommandName(commandName)
					end
				end
			end
			return false
		end,
	},

	-----------------------------------
	{
		name = "epoch",
		aliases = {},
		order = 6,
		description = "Waits until the given epoch time before executing. If the epoch time has already passed, the command will be executed right away. Combine with 'global' and 'perm' for a permanent game effect. Example: ``;globalPermEpoch(3124224000)message(green) Happy new year!``",
		executeRightAway = false,
		executeAfterThread = true,
		yieldUntilThreadComplete = true,
		action = function(task, values)
			local executionTime = unpack(values)
			local timeNow = os.time()
			local newExecutionTime = tonumber(executionTime) or timeNow + 1
			local seconds = newExecutionTime - timeNow
			local thread = main.modules.Thread.delay(seconds)
			return thread
		end,
	},

	-----------------------------------
	{
		name = "delay",
		aliases = {},
		order = 7,
		description = "Waits x amount of time before executing the command. Time can be represented in seconds as 's', minutes as 'm', hours as 'h', days as 'd', weeks as 'w' and years as 'y'. Example: ``;delay(3s)kill all``.",
		executeRightAway = false,
		executeAfterThread = true,
		yieldUntilThreadComplete = true,
		action = function(task, values)
			local timeDelay = unpack(values)
			local seconds = main.modules.DataUtil.convertTimeStringToSeconds(timeDelay)
			local thread = main.modules.Thread.delay(seconds)
			return thread
		end,
	},

	-----------------------------------
	{
		name = "loop",
		aliases = {"repeat"},
		order = 8,
		description = "Repeats a command for x iterations every y time delay. If not specified, x defaults to ∞ and y to 1s. Time can be represented in seconds as 's', minutes as 'm', hours as 'h', days as 'd', weeks as 'w' and years as 'y'. Example: ``;loop(50,1s)jump me``.",
		executeRightAway = true,
		executeAfterThread = false,
		yieldUntilThreadComplete = false,
		action = function(task, values)
			local iterations, interval = unpack(values)
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
	},

	-----------------------------------
	{
		name = "spawn",
		aliases = {},
		order = 9,
		description = "Executes the command every time the given player(s) respawn (in addition to the initial execution). This modifier only works for commands with player-related arguments.",
		executeRightAway = true,
		executeAfterThread = false,
		yieldUntilThreadComplete = false,
		action = function(task)
			local targetUser = main.modules.UserStore:getUserByUserId(task.userId)
			local targetPlayer = targetUser and targetUser.player
			if targetPlayer then
				task.persistence = main.enum.Persistence.UntilLeave
				task.janitor:add(targetPlayer.CharacterAdded:Connect(function(char)
					main.RunService.Heartbeat:Wait()
					char:WaitForChild("HumanoidRootPart")
					char:WaitForChild("Humanoid")
					task:execute()
				end), "Disconnect")
				local thread = main.modules.Thread.loopUntil(0.1, function()
					return targetUser.isDestroyed == true
				end)
				return thread
			end
		end,
	},

	-----------------------------------
	{
		name = "expire",
		aliases = {"until"},
		order = 10,
		description = "Revokes the command after its first execution plus the given time. Time can be represented in seconds as 's', minutes as 'm', hours as 'h', days as 'd', weeks as 'w' and years as 'y'. Example: ``;expire(2m30s)mute player``.",
		executeRightAway = true,
		executeAfterThread = false,
		yieldUntilThreadComplete = false,
		action = function(task, values)
			local timeDelay = unpack(values)
			local seconds = main.modules.DataUtil.convertTimeStringToSeconds(timeDelay)
			local thread = main.modules.Thread.delay(seconds, task.kill, task)
			return thread
		end,
	},

	-----------------------------------
}

-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Modifiers.dictionary.MODIFIER_NAME`` to return its item
Modifiers.dictionary = {}
Modifiers.lowerCaseNameAndAliasToModifierDictionary = {}
for _, item in pairs(Modifiers.array) do
	Modifiers.dictionary[item.name] = item
	Modifiers.lowerCaseNameAndAliasToModifierDictionary[item.name:lower()] = item
	for _, alias in pairs(item.aliases) do
		Modifiers.dictionary[alias] = item
		Modifiers.lowerCaseNameAndAliasToModifierDictionary[alias:lower()] = item
	end
end

-- SORTED ARRAY(S)
local copy = main.modules.TableUtil.copy
Modifiers.sortedNameAndAliasLengthArray = {}
for itemNameOrAlias, item in pairs(Modifiers.dictionary) do
	table.insert(Modifiers.sortedNameAndAliasLengthArray, itemNameOrAlias)
end
table.sort(Modifiers.sortedNameAndAliasLengthArray, function(a, b)
	return #a > #b
end)

Modifiers.sortedOrderArray = copy(Modifiers.array)
table.sort(Modifiers.sortedOrderArray, function(a, b)
	return a.order > b.order
end)

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

-- METHODS
function Modifiers.get(name)
	return Modifiers.lowerCaseNameAndAliasToModifierDictionary[name:lower()]
end

return Modifiers
