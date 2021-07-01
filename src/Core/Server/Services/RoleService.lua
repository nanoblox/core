-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local RoleService = System.new("Roles")
local Role = main.modules.Role
local PlayerStore = main.modules.PlayerStore
local DataUtil = main.modules.DataUtil
local TableUtil = main.modules.TableUtil
local Signal = main.modules.Signal
local roles = {}



-- EVENTS
RoleService.roleAdded = Signal.new()
RoleService.roleChanged = Signal.new()
RoleService.roleRemoved = Signal.new()

RoleService.recordAdded:Connect(function(roleUID, record)
	--warn(("ROLE '%s' ADDED!"):format(record.name))
	local role = Role.new(record)
	role.settings.UID = roleUID
	role.settings.environment = role.settings.environment or main.enum.Environment.Global
	roles[roleUID] = role
	RoleService.roleAdded:Fire(role)
end)

RoleService.recordRemoved:Connect(function(roleUID, oldRecord)
	--warn(("ROLE '%s' (UID = %s) REMOVED!"):format((oldRecord and oldRecord.name) or "*No name*", roleUID))
	local role = roles[roleUID]
	if role then
		roles[roleUID] = nil
		role:updateUsers()
		role:destroy()
	end
	RoleService.roleRemoved:Fire(role)
end)

RoleService.recordChanged:Connect(function(roleUID, propertyName, propertyValue, propertyOldValue)
	local role = roles[roleUID]
	if role then
		role.settings[propertyName] = propertyValue
		role:updateUsers()
	end
	RoleService.roleChanged:Fire(role, propertyName, propertyValue, propertyOldValue)
	--warn(("ROLE '%s' CHANGED %s to %s (from %s)"):format(tostring(role and role.name), tostring(propertyName), tostring(propertyValue), tostring(propertyOldValue)))
end)



-- PLAYERSERVICE METHOD EVENTS
function RoleService.userLoadedMethod(user)
	--------- !!!test
	RoleService.giveRoles(user, {"Manager", "Head Admin", "Admin"})
	---------
	RoleService.updateRoleInformation(user)
	user.isRolesLoaded = true
	user.rolesLoaded:Fire()
end



-- LOADED
function RoleService.loaded()
	-- Create the hidden creator role
	-- This role is important as it ensures *the owner*
	-- of the game always has top priority
	local creatorRoleUID = DataUtil.generateUID(10)
	RoleService.creatorRoleUID = creatorRoleUID
	RoleService.createRole(false, {
		UID = creatorRoleUID,
		name = "Creator_"..creatorRoleUID,
		roleOrder = 0,
		giveToCreator = true,
	})
end



-- METHODS
function RoleService.generateRecord()
	return {
		-- Appearance
		name = "Unnamed Role",
		color = Color3.fromRGB(255, 255, 255),

		-- Behaviour
		environment = main.enum.Environment.Global,
		roleOrder = 0,
		hidden = false, -- when 'true', makes it so the role can only be viewed by people who own it, or by people who can edit it
		nonadmin = false, -- This is solely for the 'nonadmins' and 'admins' qualifiers

		-- Role Givers
		give = {
			toEveryone = false,
			toCreator = false,
			toUsers = {},
			toUsersWithGamepasses = {},
			toUsersWithAssets = {},  -- Note: impossible to tell unless in game
			toUsersOfRanksInGroup = {},  -- Note: impossible to tell unless in game
			toFriendsOfUsers = {},
			toVipServerOwner = false,
			toVipServerPlayers = false,
			toPremiumUsers = false,  -- Note: impossible to tell unless in game
			toStarCreators = false,
			whenMinimumAccountAgeGiverEnabled = false,
			toUsersWithMinimumAccountAge = 7,  -- Note: impossible to tell unless in game
			whenDailyLoginStreakGiverEnabled = false,
			toUsersWithDailyLoginStreak = 14,
			onDeveloperProductPurchases = {},
		},
		
		-- Role takers
		take = {
			whenXCommandExecutionsTakerEnabled = true,
			afterXCommandExecutions = 1,
			afterRespawning = false,
		},
		
		-- Command Inheritance
		inheritCommands = {
			withNames = {},
			withTags = {},
			fromAllRoles = false,
			fromJuniorRoles = true,
			fromSpecificRoles = {},
		},
		
		-- Limit Abuse
		limit = {
			whenRequestsPerIntervalCapEnabled = true, -- I may have set this up in tasks already. Instead, make sure this goes into VERIFY and increases for *every command* within there
			requestsPerIntervalCapRefresh = 10,
			requestsPerIntervalCapAmount = 10,
			whenRequestCooldownEnabled = false,
			whenGlobalExecutionsPerIntervalCapEnabled = true,
			globalExecutionsPerIntervalCapRefresh = 20,
			globalExecutionsPerIntervalCapAmount = 5,
			repeatCommands = true, -- this prevents a command from being repeated twice before finishing for users/servers. important: make sure to modify TaskService 'preventRepeatCommands'.
			whenScaleCapEnabled = true,
			scaleCapAmount = 5,
			denylistedIDs = true,
			toAllowlistedIDs = false,
			whenQualifierTargetCapEnabled = false,
			qualifierTargetCapAmount = 1,
		},
		
		-- Individual Powers
		canUse = {
			all = false,
			commandsOnOthers = true,
			commandsOnFriends = true,
			cmdbar1 = false,
			cmdbar2 = false,
		},

		-- Modifiers
		canUseModifier = {
			all = false,
			preview = true,
			random = true,
			perm = false,
			global = false,
			undo = true,
			epoch = true,
			delay = true,
			loop = false,
			spawn = true,
			expire = true,
		},
		
		-- Client Prompts
		prompts = {
			welcomeRankNotice = true,
		},
		
		canBlockTasksFrom = { -- A block prevents that class of users using commands on the player
			all = false,
			seniors = false,
			peers = false,
			juniors = true,
		},

		canRevokeTasksFrom = {
			all = false,
			seniors = false,
			peers = false,
			juniors = true,
		},
		
		-- Client Permissions & Pages
		canView = {
			all = false,
			unusableCommands = true,
			rolesList = true,
			tempRoles = true,
			permRoles = false,
			bans = false,
			warnings = false,
			logs = false,
			systemSettings = false,
			playerSettings = false,
		},

		canEdit = {
			all = false,
			unusableCommands = false,
			rolesList = false,
			tempRoles = false,
			permRoles = false,
			bans = false,
			warnings = false,
			logs = false,
			systemSettings = false,
			playerSettings = false,
		},
		
		-- Custom Bubble Chat
		customBubble = {
			enabled = false,
			imageColor = Color3.fromRGB(255, 255, 255),
			textColor = Color3.fromRGB(255, 255, 255),
			textFont = "SourceSans",
		},
		
		-- Custom Menu Chat
		customChat = {
			enabled = false,
			nameColor = Color3.fromRGB(255, 255, 255),
			chatColor = Color3.fromRGB(255, 255, 255),
			chatTags = {
				--[[{
					tagText = "",
					tagColor = Color3.fromRGB(255, 255, 255),
				}--]]
			},
		},

		-- Custom Title
		customTitle = {
			enabled = false,
			text = "Unnamed Title",
			primaryColor = Color3.fromRGB(255, 255, 255),
			strokeColor = Color3.fromRGB(255, 255, 255),
		},
	}
end

function RoleService.createRole(isGlobal, properties)
	-- The UID is a string to unqiquely identify each role
	-- We use this as the key instead of the roles name so that records
	-- can persist as the same instance even after being renamed
	local key = (properties and properties.UID) or DataUtil.generateUID(10)
	RoleService:createRecord(key, isGlobal, properties)
	local role = RoleService.getRole(key)
	return role
end

function RoleService.getRole(nameOrUID)
	local role = RoleService.getRoleByUID(nameOrUID)
	if not role then
		role = RoleService.getRoleByName(nameOrUID)
	end
	if not role then
		role = RoleService.getRoleByLowerName(nameOrUID)
	end
	return role
end

function RoleService.getCreatorRole(nameOrUID)
	return RoleService.getRole(RoleService.creatorRoleUID)
end

function RoleService.getRoleByUID(roleUID)
	local role = roles[roleUID]
	if not role then
		return false
	end
	return role
end

function RoleService.getRoleByName(name)
	for roleUID, role in pairs(roles) do
		if role.settings.name == name then
			return role
		end
	end
	return false
end

function RoleService.getRoleByLowerName(name)
	local lowerName = name:lower()
	for roleUID, role in pairs(roles) do
		if (role.settings.name):lower() == lowerName then
			return role
		end
	end
	return false
end

function RoleService.getRoleByLowerShorthandName(name)
	local lowerName = name:lower()
	local length = string.len(lowerName)
	for roleUID, role in pairs(roles) do
		if (role.settings.name):lower():sub(1,length) == lowerName then
			return role
		end
	end
	return false
end

function RoleService.getRoles()
	local allRoles = {}
	for name, role in pairs(roles) do
		table.insert(allRoles, role)
	end
	return allRoles
end

function RoleService.updateRole(nameOrUID, propertiesToUpdate)
	local role = RoleService.getRole(nameOrUID)
	assert(role, ("role '%s' not found!"):format(tostring(nameOrUID)))
	RoleService:updateRecord(role.settings.UID, propertiesToUpdate)
	return true
end

function RoleService.removeRole(nameOrUID)
	local role = RoleService.getRole(nameOrUID)
	assert(role, ("role '%s' not found!"):format(tostring(nameOrUID)))
	RoleService:removeRecord(role.settings.UID)
	return true
end

local function sortRoles(tableOfRoleUIDsOrNames, approveRole)
	-- This converts input into an array if a dictionary
	local arrayOfRoles = tableOfRoleUIDsOrNames
	if #tableOfRoleUIDsOrNames == 0 then
		arrayOfRoles = {}
		for roleUID, _ in pairs(tableOfRoleUIDsOrNames) do
			table.insert(arrayOfRoles, roleUID)
		end
	end
	local currentOrder, selectedRole = nil, nil
	for _, roleUID in pairs(arrayOfRoles) do
		local role = RoleService.getRole(roleUID)
		if role and (selectedRole == nil or approveRole(role.settings.roleOrder, currentOrder)) then
			currentOrder, selectedRole = role.settings.roleOrder, role
		end
	end
	if not selectedRole then
		selectedRole = {
			roleOrder = 100,
			unselectedRole = true,
			name = "RoleFailed"
		}
	end
	return selectedRole
end

function RoleService.getHighestRole(tableOfRoleUIDsOrNames) -- i.e. the most senior role
	return sortRoles(tableOfRoleUIDsOrNames, function(roleOrder, currentOrder)
		return roleOrder < currentOrder
	end)
end

function RoleService.getLowestRole(tableOfRoleUIDsOrNames) -- i.e. the most junior role
	return sortRoles(tableOfRoleUIDsOrNames, function(roleOrder, currentOrder)
		return roleOrder > currentOrder
	end)
end

function RoleService.isSenior(roleA, roleB)
	assert(typeof(roleA) == "table", "roleA must be a role or table!")
	assert(typeof(roleB) == "table", "roleB must be a role or table!")
	return roleA.roleOrder < roleB.roleOrder
end

function RoleService.isPeer(roleA, roleB)
	assert(typeof(roleA) == "table", "roleA must be a role or table!")
	assert(typeof(roleB) == "table", "roleB must be a role or table!")
	return roleA.roleOrder == roleB.roleOrder
end

function RoleService.isJunior(roleA, roleB)
	assert(typeof(roleA) == "table", "roleA must be a role or table!")
	assert(typeof(roleB) == "table", "roleB must be a role or table!")
	return roleA.roleOrder > roleB.roleOrder
end

function RoleService._getSettingTablesFromPathways(...)
	local settingTables = {}
	for _, stringSetting in pairs({...}) do
		local tableSetting = DataUtil.getPathwayArrayFromString(stringSetting)
		table.insert(settingTables, tableSetting)
	end
	return settingTables
end

function RoleService._getCombinedSettingInfo(user, ...)
	local roleInformation = user.temp:get("roleInformation")
	local combinedSettingInfo = {}
	local settingTables = RoleService._getSettingTablesFromPathways(...)
	if roleInformation then
		for _, settingTable in pairs(settingTables) do
			local settingInfo = roleInformation:get(unpack(settingTable))
			if settingInfo then
				for k,v in pairs(settingInfo) do
					combinedSettingInfo[k] = v
				end
			end
		end
	end
	return combinedSettingInfo
end

function RoleService.verifySettings(user, ...)
	local combinedSettingInfo = RoleService._getCombinedSettingInfo(user, ...)
	local methods = {}
	function methods.areSome(value)
		if combinedSettingInfo[tostring(value)] then
			return true
		end
		return false
	end
	function methods.areSomeNot(value)
		local stringValue = tostring(value)
		for settingValue, _ in pairs(combinedSettingInfo) do
			if settingValue ~= stringValue then
				return true
			end
		end
		return false
	end
	function methods.areAll(value)
		local stringValue = tostring(value)
		for settingValue, _ in pairs(combinedSettingInfo) do
			if settingValue ~= stringValue then
				return false
			end
		end
		return true
	end
	function methods.areAllNot(value)
		if combinedSettingInfo[tostring(value)] == nil then
			return true
		end
		return false
	end
	function methods.have(value)
		if combinedSettingInfo[tostring(value)] then
			return true
		end
		return false
	end
	return methods
end

function RoleService.getMaxValueFromSettings(user, ...)
	local combinedSettingInfo = RoleService._getCombinedSettingInfo(user, ...)
	local maxValue
	for settingValue, _ in pairs(combinedSettingInfo) do
		local number = tonumber(settingValue)
		if number and (maxValue == nil or number > maxValue) then
			maxValue = number
		end
	end
	return maxValue
end

function RoleService.getMinValueFromSettings(user, ...)
	local combinedSettingInfo = RoleService._getCombinedSettingInfo(user, ...)
	local minValue
	for settingValue, _ in pairs(combinedSettingInfo) do
		local number = tonumber(settingValue)
		if number and (minValue == nil or number < minValue) then
			minValue = number
		end
	end
	return minValue
end

function RoleService.getHighestRoleSetting(user, settingPathway)
	local userRoles = user.temp.roles or {}
	local highestRole = RoleService.getHighestRole(userRoles)
	if highestRole then
		local settingTable = RoleService._getSettingTablesFromPathways(settingPathway)[1]
		return main.modules.State.getSimple(highestRole, settingTable), highestRole
	end
end

function RoleService.getEnvironment(user)
	local roleInformation = user.temp:get("roleInformation")
	local environment = roleInformation and roleInformation._collectiveEnvironment
	return environment
end

function RoleService.updateRoleInformation(user)
	local userRoles = user.temp:getOrSetup("roles")
	local information = {}
	local function scanTable(roleTable, tableToUpdate)
		for key, value in pairs(roleTable) do
			local stringKey = tostring(key)
			local ignoreValueTypes = {
				["function"] = true,
				["table"] = true,
			}
			local valueType = typeof(value)
			if ignoreValueTypes[valueType] then
				if valueType == "table" then
					local newTableToUpdate = tableToUpdate[stringKey]
					if not newTableToUpdate then
						newTableToUpdate = {}
						tableToUpdate[stringKey] = newTableToUpdate
					end
					scanTable(value, newTableToUpdate)
				end
				continue
			end
			local infoTable = tableToUpdate[stringKey]
			if not infoTable then
				infoTable = {}
				tableToUpdate[stringKey] = infoTable
			end
			local stringValue = tostring(value)
			infoTable[stringValue] = true
		end
	end
	for roleKey, _ in pairs(userRoles) do
		local role = RoleService.getRoleByUID(roleKey)
		if role then
			-- This setups up the info dictionaries for each setting
			scanTable(role.settings, information)
			-- This determines the environment across *all* roles
			-- If the collection of Roles contain 'Private' *and* 'Global', then set to 'Multiple'
			local roleEnvironment = role.settings.environment
			local existingEnvironment = information["_collectiveEnvironment"]
			local newEnvironment = roleEnvironment
			if existingEnvironment and existingEnvironment ~= roleEnvironment then
				newEnvironment = main.enum.Environment.Multiple
			end
			information["_collectiveEnvironment"] = newEnvironment
		end
	end
	user.temp:set("roleInformation", information)
end
--RoleService.updateRoleInformation = main.modules.FunctionUtil.preventMultiFrameUpdates(RoleService.updateRoleInformation)

function RoleService.giveRoles(user, arrayOfRoleNamesOrUIDs, roleType)
	for _, roleNameOrUID in pairs(arrayOfRoleNamesOrUIDs) do
		local role = RoleService.getRole(roleNameOrUID)
		if role then
			role:give(user, roleType)
		else
			warn(("Nanoblox: failed to give role '%s'; role does not exist!"):format(roleNameOrUID))
		end
	end
end



--[[
local main = require(game.Nanoblox)
local RoleService = main.services.RoleService
RoleService.createRole(true, {
	name = "AAA"
})


local main = require(game.Nanoblox)
local SystemStore = main.modules.SystemStore
local user = SystemStore:getUser("User")
main.modules.TableUtil.print(user._data, "", true)

print("A")
local main = require(game.Nanoblox).getFramework()
print("B")
local SystemStore = main.modules.SystemStore
print("C")
local user = SystemStore:getUser("Roles")
print("D")



local main = require(game.Nanoblox)
local RoleService = main.services.RoleService
local roleKey = "Manager"
RoleService.removeRole(roleKey)

local main = require(game.Nanoblox)
local RoleService = main.services.RoleService
local roleKey = "Manager"
--RoleService.updateRole(roleKey, {yoo = {math.random(1,10000)}})
local randomInt = math.random(1,10000)
print("randomInt = ", randomInt)
RoleService.updateRole(roleKey, {
	yoo = {
		subyooo = {
			subsubyoooo = {
				hiMom = randomInt
			}
		}
	}
})

local main = require(game.Nanoblox)
local SystemStore = main.modules.SystemStore
local user = SystemStore:getUser("NilledData")
main.modules.TableUtil.print(user._data, "", true)


local main = require(game.Nanoblox)
local RoleService = main.services.RoleService
local roleKeyOrName = "Mod"
print(RoleService.getRole(roleKeyOrName))

--]]
return RoleService