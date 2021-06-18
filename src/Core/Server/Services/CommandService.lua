-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local CommandService = System.new("Commands")
local defaultCommands = {}
CommandService.remotes = {}



-- START
function CommandService.start()

	-- This retrieves all commands present on server start, applies tags/other details accoridngly and adds them to 'defaultCommands'
	local checkedAliases = {}
	local checkedCommandNames = {}
	local DUPLICATE_COMMAND_WARNING = "Duplicate command names are not permitted! Rename '%s' to something different."
	local DUPLICTE_ALIAS_WARNING = "Duplicate command aliases are not permitted! Rename '%s' to something different."
	local DUPLICTE_BOTH_WARNING = "Duplicate command names/aliases are not permitted! Rename '%s' to something different."
	local function setupCommands(group, tags)
		local groupClass = group.ClassName
		local thisTag = (groupClass == "Folder" or groupClass == "Configuration") and group.Name:lower()
		local newTags = tags and {unpack(tags)} or {}
		if thisTag then
			table.insert(newTags, thisTag)
		end
		for _, instance in pairs(group:GetChildren()) do
			if instance:IsA("ModuleScript") then
				local command = require(instance)
				local commandName = instance.Name
				local commandNameLower = commandName:lower()
				command.tags = (typeof(command.tags == "table") and command.tags) or {}
				command.aliases = (typeof(command.aliases == "table") and command.aliases) or {}
				command.name = commandName
				for _, tagToAdd in pairs(newTags) do
					table.insert(command.tags, tagToAdd)
				end
				for _, alias in pairs(command.aliases) do
					local aliasName = tostring(alias)
					local aliasLower = aliasName:lower()
					if checkedAliases[aliasLower] or checkedCommandNames[aliasLower] then
						error((DUPLICTE_ALIAS_WARNING):format(aliasName))
					end
					checkedAliases[aliasLower] = true
				end
				local client = instance:FindFirstChild("Client") or instance:FindFirstChild("client")
				if client then
					client.Name = commandNameLower
					client.Parent = main.shared.Modules.ClientCommands
				end
				if checkedCommandNames[commandNameLower] then
					error((DUPLICATE_COMMAND_WARNING):format(commandName))
				elseif checkedAliases[commandNameLower] then
					error((DUPLICTE_BOTH_WARNING):format(commandNameLower))
				end
				checkedCommandNames[commandNameLower] = true
				defaultCommands[commandName] = command
			else
				setupCommands(instance, newTags)
			end
		end
	end
	setupCommands(main.server.Extensions.Commands)



	-- Setup remotes
    local previewCommand = main.modules.Remote.new("previewCommand")
    CommandService.remotes.previewCommand = previewCommand

	local CLIENT_REQUEST_LIMIT = 10
	local REFRESH_INTERVAL = 5

	local requestBatch = main.modules.Remote.new("requestBatch", CLIENT_REQUEST_LIMIT, REFRESH_INTERVAL)
    CommandService.remotes.requestBatch = requestBatch
	requestBatch.onServerInvoke = function(player, batch)
		local callerUser = main.modules.PlayerStore:getUser(player)
		local success, approved = CommandService.verifyThenExecuteBatch(callerUser, batch):await()
		if success and approved then
			return true
		end
		return false
	end

	local requestStatement = main.modules.Remote.new("requestStatement", CLIENT_REQUEST_LIMIT, REFRESH_INTERVAL)
    CommandService.remotes.requestStatement = requestStatement
	requestStatement.onServerInvoke = function(player, statement)
		local callerUser = main.modules.PlayerStore:getUser(player)
		local success, approved = CommandService.verifyThenExecuteStatement(callerUser, statement):await()
		if success and approved then
			return true
		end
		return false
	end

	local requestChat = main.modules.Remote.new("requestChat", CLIENT_REQUEST_LIMIT, REFRESH_INTERVAL)
    CommandService.remotes.requestChat = requestChat
	requestChat.onServerInvoke = function(player, message)
		if typeof(message) ~= "string" then
			return false, "Invalid message"
		end
		local callerUser = main.modules.PlayerStore:getUser(player)
		local success, approved = CommandService.processMessage(callerUser, message):await()
		if success and approved then
			return true
		end
		return false
	end
    
end



-- PLAYER USER LOADED
function CommandService.userLoadedMethod(user)
	CommandService.setupParsePatterns(user)
end



-- LOADED
function CommandService.loaded()
	
	-- Setup globals
	CommandService.executeStatementGloballySender = main.services.GlobalService.createSender("executeStatementGlobally")
	CommandService.executeStatementGloballyReceiver = main.services.GlobalService.createReceiver("executeStatementGlobally")
	CommandService.executeStatementGloballyReceiver.onGlobalEvent:Connect(function(callerUserId, statement)
		CommandService.executeStatement(callerUserId, statement)
	end)

	-- Convert default commands to service commands
	for name, details in pairs(defaultCommands) do
		CommandService.createCommand(name, details)
	end

	-- Setup auto sorters
	local records = CommandService.records
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
	records:setTable("lowerCaseNameAndAliasToCommandDictionary", function()
		local dictionary = {}
		for _, record in pairs(records) do
			dictionary[record.name:lower()] = record
			for _, alias in pairs(record.aliases) do
				dictionary[alias:lower()] = record
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
	records:setTable("lowerCaseTagToGroupArray", function()
		local tagGroups = {}
		for _, record in pairs(records) do
			local tags = record.tags or {}
			for _, tagName in pairs(tags) do
				local tagNameLower = tostring(tagName):lower()
				local group = tagGroups[tagNameLower]
				if not group then
					group = {}
					tagGroups[tagNameLower] = group
				end
				table.insert(group, record.name)
			end
		end
		return tagGroups
	end)

end



-- EVENTS
CommandService.recordAdded:Connect(function(commandName, record)
	local args = record.args
	if args then
		for _, argName in pairs(args) do
			local argItem = main.modules.Parser.Args.get(argName)
			if not argItem then
				warn(("Nanoblox: '%s' is not a valid arg name or alias!"):format(argName))
			end
		end
	end
	--warn(("COMMAND '%s' ADDED!"):format(commandName))
end)

CommandService.recordRemoved:Connect(function(commandName)
	--warn(("COMMAND '%s' REMOVED!"):format(commandName))
end)

CommandService.recordChanged:Connect(function(commandName, propertyName, propertyValue, propertyOldValue)
	--warn(("BAN '%s' CHANGED %s to %s"):format(commandName, tostring(propertyName), tostring(propertyValue)))
end)



-- METHODS
function CommandService.generateRecord(key)
	return defaultCommands[key] or {
		name = "",
		description = "",
		aliases	= {},
		opposites = {},
		tags = {},
		prefixes = {},
		contributors = {},
		blockPeers = false,
		blockJuniors = false,
		autoPreview = false,
		requiresRig = main.enum.HumanoidRigType.None,
		revokeRepeats = false,
		preventRepeats = main.enum.TriStateSetting.Default,
		cooldown = 0,
		persistence = main.enum.Persistence.None,
		args = {},
	}
end

function CommandService.createCommand(name, properties)
	local key = properties.name
	if not key then
		key = name
		properties.name = key
	end
	local record = CommandService:createRecord(key, false, properties)
	return record
end

function CommandService.getCommand(name)
	local command = CommandService:getRecord(name)
	if not command then
		command = CommandService.getTable("lowerCaseNameAndAliasToCommandDictionary")[name:lower()]
		if not command then
			return false
		end
	end
	return command
end
 
function CommandService.getCommands()
	return CommandService:getRecords()
end

function CommandService.getCommandsByTag(tag)
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
	return CommandService.records:getTable(name)
end 

function CommandService.setupParsePatterns(user)
	-- This dynamically updates the players 'parsePatterns' when the users settings change instead of having to parse them every chat message
	local PARSE_SETTINGS = {
		commandStatementsFromBatch = {
			settingName = "prefixes",
			parse = function(settingValue)
				return string.format(
					"%s([^%s]+)",
					";", --ClientSettings.prefix,
					";" --ClientSettings.prefix
				)
			end,
		},
        descriptionsFromCommandStatement = {
			settingName = "descriptorSeparator",
			parse = function(settingValue)
				return string.format(
					"%s?([^%s]+)",
					" ", --ClientSettings.descriptorSeparator,
					" " --ClientSettings.descriptorSeparator
				)
			end,
		},
        argumentsFromCollection = {
			settingName = "collective",
			parse = function(settingValue)
				return string.format(
					"([^%s]+)%s?",
					",", --ClientSettings.collective,
					"," --ClientSettings.collective
				)
			end,
		},
        capsuleFromKeyword = {
			settingName = "argCapsule",
			parse = function(settingValue)
				return string.format(
					"%%(%s%%)", --Capsule
					string.format("(%s)", ".-")
				)
			end
		},
	}
	local validSettingNames = {}
	local playerSettings = user.perm:getOrSetup("playerSettings")
	playerSettings.changed:Connect(function(settingName, value)
		if validSettingNames[settingName] then
			user.temp.parsePatterns:set(settingName, value)
		end
	end)
	user.temp:set("parsePatterns", {})
	for _, detail in pairs(PARSE_SETTINGS) do
		local settingName = detail.settingName
		local settingValue = main.services.SettingService.getPlayerSetting(settingName, user)
		validSettingNames[settingName] = true
		user.temp.parsePatterns:set(settingName, settingValue)
	end
end

function CommandService.createFakeUser(userId)
	local DEFAULT_USER_ID = 1
	local user = {}
	user.userId = userId or DEFAULT_USER_ID
	user.name = "Server"
	user.displayName = "Server"
	user.perm = main.modules.State.new({
		playerSettings = {
			playerIdentifier = "@",
			playerUndefinedSearch = main.enum.PlayerSearch.UserName,
			playerDefinedSearch = main.enum.PlayerSearch.DisplayName,
		}
	}, true)
	user.temp = main.modules.State.new(nil, true)
	user.roles = {}
	CommandService.setupParsePatterns(user)
	-- if DEFAULT_USER_ID then get creator role, else use RoleService
	main.services.RoleService.getCreatorRole():give(user, main.enum.RoleType.Server)
	return user
end

function CommandService.processMessage(callerUser, message)
	local batch = main.modules.Parser.parseMessage(message, callerUser)
	return CommandService.verifyThenExecuteBatch(callerUser, batch, message)
end

function CommandService.convertStatementToRealNames(statement)
	-- We modify the statement to convert all aliases into the actual names for commands and modifiers
	if statement.converted then
		return
	end
	statement.converted = true
	local tablesToConvertToRealNames = {
		["commands"] = {CommandService, "getCommand"},
		["modifiers"] = {main.modules.Parser.Modifiers, "get"},
	}
	for tableName, getMethodDetail in pairs(tablesToConvertToRealNames) do
		local table = statement[tableName]
		if table then
			local getTable = getMethodDetail[1]
			local getMethod = getTable[getMethodDetail[2]]
			local newTable = {}
			local originalTableName = "original"..tableName:sub(1,1):upper()..tableName:sub(2)
			local originalTable = {}
			for name, value in pairs(table) do
				local returnValue = getMethod(name)
				local realName = returnValue and string.lower(returnValue.name)
				if realName then
					newTable[realName] = value
				end
				originalTable[name] = true
			end
			statement[originalTableName] = originalTable
			statement[tableName] = newTable
		end
	end
	print("requested statement: ", statement)
end

function CommandService.verifyThenExecuteStatement(callerUser, statement)
	local callerUserId = callerUser.userId
	local callerPlayer = callerUser.player
	local Promise = main.modules.Promise
	return CommandService.verifyStatement(callerUser, statement)
		:andThen(function(approved, noticeDetails)
			if callerPlayer then
				for _, detail in pairs(noticeDetails) do
					local method = main.services.MessageService[detail[1]]
					method(callerPlayer, detail[2])
				end
			end
			if approved then
				return Promise.new(function(resolve, reject)
					local sucess, tasksOrWarning = CommandService.executeStatement(callerUserId, statement):await()
					if sucess then
						return resolve(true, tasksOrWarning)
					end
					reject(tasksOrWarning)
				end)
			end
			return false
		end)
end

function CommandService.verifyThenExecuteBatch(callerUser, batch, message)
	local callerUserId = callerUser.userId
	local Promise = main.modules.Promise
	return Promise.defer(function(resolve, reject)
		if type(batch) ~= "table" then
			return resolve(false, "The batch must be a table!")
		end
		local approvedPromises = {}
		for _, statement in pairs(batch) do
			if type(batch) ~= "table" then
				return resolve(false, "Statements must be a table!")
			end
			statement.message = message
			table.insert(approvedPromises, Promise.new(function(subResolve, subReject)
				local success, approved, noticeDetails = CommandService.verifyStatement(callerUser, statement):await()
				if success and approved then
					subResolve()
				elseif not success then
					reject(approved)
					subReject()
				else
					subReject()
				end
			end))
		end
		local approvedAllStatements = Promise.all(approvedPromises):await()
		if not approvedAllStatements then
			return resolve(false, "Invalid permission to execute all statements")
		end
		local collectiveTasks = {}
		for _, statement in pairs(batch) do
			local sucess, tasks = CommandService.executeStatement(callerUserId, statement):await()
			if sucess then
				for _, task in pairs(tasks) do
					table.insert(collectiveTasks, task)
				end
			end
		end
		resolve(true, collectiveTasks)
	end)
end

function CommandService.verifyStatement(callerUser, statement)
	local approved = true
	local details = {}
	local Promise = main.modules.Promise
	local RoleService = main.services.RoleService
	local Args = main.modules.Parser.Args
	local callerUserId = callerUser.userId

	-- argItem.verifyCanUse can sometimes be asynchronous therefore we return and resolve a Promise
	local promise = Promise.defer(function(resolve, reject)
		
		if typeof(statement) ~= "table" then
			return resolve(false, {{"notice", {
				text = "Statements must be tables!",
				error = true,
			}}})
		end
		CommandService.convertStatementToRealNames(statement)
		
		local jobId = statement.jobId
		local statementCommands = statement.commands
		local modifiers = statement.modifiers
		local qualifiers = statement.qualifiers
		print("statementCommands = ", statementCommands)
		
		if not statementCommands then
			return resolve(false, {{"notice", {
				text = "Failed to execute command as it does not exist!",
				error = true,
			}}})
		end

		-- This verifies the caller can use the given commands and associated arguments
		for commandName, arguments in pairs(statementCommands) do
			
			-- If arguments is not a table, convert to one
			if typeof(arguments) ~= "table" then
				arguments = {}
				statementCommands[commandName] = arguments
			end

			-- Does the command exist
			local command = main.services.CommandService.getCommand(commandName)
			if not command then
				return resolve(false, {{"notice", {
					text = string.format("'%s' is an invalid command name!", commandName),
					error = true,
				}}})
			end

			-- Does the caller have permission to use it
			local commandNameLower = string.lower(commandName)
			if not RoleService.verifySettings(callerUser, "commands").have(commandNameLower) then
				--!!! RE_ENABLE THIS
				--[[return resolve(false, {{"notice", {
					text = string.format("You do not have permission to use command '%s'!", commandName),
					error = true,
				}}})
				return--]]
			end

			-- Does the caller have permission to target multiple players
			local targetPlayers = Args.get("player"):parse(statement.qualifiers, callerUserId)
			if RoleService.verifySettings(callerUser, "limit.whenQualifierTargetCapEnabled").areAll(true) then
				local limitAmount = RoleService.getMaxValueFromSettings(callerUser, "limit.qualifierTargetCapAmount")
				if #targetPlayers > limitAmount then
					local finalMessage
					if limitAmount == 1 then
						finalMessage = ("1 player")
					else
						finalMessage = string.format("%s players", limitAmount)
					end
					return resolve(false, {{"notice", {
						text = string.format("You're only permitted to target %s per statement!", finalMessage),
						error = true,
					}}})
				end
			end

			-- Does the caller have permission to use the associated arguments of the command
			local argStringIndex = 0
			for _, argNameOrAlias in pairs(command.args) do
				local argItem = Args.get(argNameOrAlias)
				if argStringIndex == 0 and argItem.playerArg then
					continue
				end
				argStringIndex += 1
				local argString = arguments[argStringIndex]
				if argItem.verifyCanUse and not (modifiers.undo or modifiers.preview) then
					local canUseArg, deniedReason = argItem:verifyCanUse(callerUser, argString)
					if not canUseArg then
						return resolve(false, {{"notice", {
							text = deniedReason,
							error = true,
						}}})
					end
				end
			end

		end

		-- This adds an additional notification if global as these commands can take longer to execute
		if modifiers and modifiers.global then
			table.insert(details, {"notice", {
				text = "Executing global command...",
				error = false,
			}})
		end
		
		resolve(approved, details)
	end)

	return promise:andThen(function(approved, noticeDetails)
		-- This fires off any notifications to the caller
		local callerPlayer = callerUser.player
		if callerPlayer then
			for _, detail in pairs(noticeDetails) do
				local method = main.services.MessageService[detail[1]]
				method(callerPlayer, detail[2])
			end
		end
		return approved, noticeDetails
	end)
end

function CommandService.executeStatement(callerUserId, statement)

	CommandService.convertStatementToRealNames(statement)

	statement.commands = statement.commands or {}
	statement.modifiers = statement.modifiers or {}
	statement.qualifiers = statement.qualifiers or {}

	-- If 'player' instance detected within qualifiers, convert to player.Name
	for qualifierKey, qualifierTable in pairs(statement.qualifiers) do
		if typeof(qualifierKey) == "Instance" and qualifierKey:IsA("Player") then
			local callerUser = main.modules.PlayerStore:getUserByUserId(callerUserId)
			local playerDefinedSearch = main.services.SettingService.getPlayerSetting("playerIdentifier", callerUser)
			local playerName = qualifierKey.Name
			if playerDefinedSearch == main.enum.PlayerSearch.UserName or playerDefinedSearch == main.enum.PlayerSearch.UserNameAndDisplayName then
				local playerIdentifier = main.services.SettingService.getPlayerSetting("playerIdentifier", callerUser)
				playerName = tostring(playerIdentifier)..playerName
				print("FINALLLLLLLLL playerName = ", playerName)
			end
			statement.qualifiers[qualifierKey] = nil
			statement.qualifiers[playerName] = qualifierTable
		end
	end

	-- This enables the preview modifier if command.autoPreview is true
	-- or bypasses the preview modifier entirely if the request is from the client
	if statement.fromClient then
		statement.modifiers.preview = nil
	else
		for commandName, arguments in pairs(statement.commands) do
			local command = CommandService.getCommand(commandName)
			if command.autoPreview then
				statement.modifiers.preview = statement.modifiers.preview or true
				break
			end
		end
	end

	-- This handles any present modifiers
	-- If the modifier preAction value returns false then cancel the execution
	local Promise = main.modules.Promise
	local Modifiers = main.modules.Parser.Modifiers
	for modifierName, _ in pairs(statement.modifiers) do
		local modifierItem = Modifiers.get(modifierName)
		if modifierItem then
			local continueExecution = modifierItem.preAction(callerUserId, statement)
			if not continueExecution then
				return Promise.new(function(resolve)
					resolve({})
				end)
			end
		end
	end

	local Args = main.modules.Parser.Args
	local promises = {}
	local tasks = {}
	local isPermModifier = statement.modifiers.perm
	local isGlobalModifier = statement.modifiers.wasGlobal
	for commandName, arguments in pairs(statement.commands) do
		
		local command = CommandService.getCommand(commandName)
		local executeForEachPlayerFirstArg = Args.executeForEachPlayerArgsDictionary[string.lower(command.args[1])]
		local TaskService = main.services.TaskService
		local properties = TaskService.generateRecord()
		properties.callerUserId = callerUserId
		properties.commandName = commandName
		properties.args = arguments or properties.args
		properties.modifiers = statement.modifiers

		-- Its important to split commands into specific users for most cases so that the command can
		-- be easily reapplied if the player rejoins (for ones where the perm modifier is present)
		-- The one exception for this is when a global modifier is present. In this scenerio, don't save
		-- specific targetPlayers, simply use the qualifiers instead to select a general audience relevant for
		-- the particular server at time of exection.
		-- e.g. ``;permLoopKillAll`` will save each specific targetPlayer within that server and permanetly loop kill them
		-- while ``;globalLoopKillAll`` will permanently save the loop kill action and execute this within all
		-- servers repeatidly
		local addToPerm = false
		local splitIntoUsers = false
		if isPermModifier then
			if isGlobalModifier then
				addToPerm = true
			elseif executeForEachPlayerFirstArg then
				addToPerm = true
				splitIntoUsers = true
			end
		else
			splitIntoUsers = executeForEachPlayerFirstArg
		end
		if not splitIntoUsers then
			properties.qualifiers = statement.qualifiers or properties.qualifiers
			local task = main.services.TaskService.createTask(addToPerm, properties)
			if task then
				table.insert(tasks, task)
			end
		else
			table.insert(promises, Promise.defer(function(resolve)
				local targetPlayers = Args.get("player"):parse(statement.qualifiers, callerUserId)
				for _, plr in pairs(targetPlayers) do
					local newProperties = main.modules.TableUtil.copy(properties)
					newProperties.playerUserId = plr.UserId
					local task = main.services.TaskService.createTask(addToPerm, newProperties)
					if task then
						table.insert(tasks, task)
					end
				end
				resolve()
			end):catch(warn))
		end
	end
	return Promise.all(promises)
		:andThen(function()
			return tasks
		end)
end

function CommandService.executeSimpleStatement(callerUserId, commandName, commandArgsArray, qualifiersDictionary, modifiersDictionary)
	local statement = {
		commands = {},
		qualifiers = qualifiersDictionary or {},
		modifiers = modifiersDictionary or {},
	}
	if commandName then
		statement.commands[commandName] = commandArgsArray
	end
	return CommandService.executeStatement(callerUserId, statement)
end

--[[

local statement = {
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