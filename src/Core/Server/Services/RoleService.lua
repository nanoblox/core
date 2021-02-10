-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local RoleService = System.new("Roles")
local systemUser = RoleService.user
local Role = main.modules.Role
local PlayerStore = main.modules.PlayerStore
local DataUtil = main.modules.DataUtil
local TableUtil = main.modules.TableUtil
local roles = {}



-- EVENTS
RoleService.recordAdded:Connect(function(roleUID, record)
	--warn(("ROLE '%s' ADDED!"):format(record.name))
	local role = Role.new(record)
	role.UID = roleUID
	roles[roleUID] = role
end)

RoleService.recordRemoved:Connect(function(roleUID, oldRecord)
	--warn(("ROLE '%s' (UID = %s) REMOVED!"):format((oldRecord and oldRecord.name) or "*No name*", roleUID))
	local role = roles[roleUID]
	if role then
		role:destroy()
		roles[roleUID] = nil
	end
end)

RoleService.recordChanged:Connect(function(roleUID, propertyName, propertyValue, propertyOldValue)
	local role = roles[roleUID]
	if role then
		role[propertyName] = propertyValue
	end
	--warn(("ROLE '%s' CHANGED %s to %s (from %s)"):format(tostring(role and role.name), tostring(propertyName), tostring(propertyValue), tostring(propertyOldValue)))
end)



-- PLAYERSERVICE METHOD EVENTS
function RoleService.userLoadedMethod(user)
	-- Load user roles
	
	-- End
	user.isRolesLoaded = true
	user.rolesLoaded:Fire()
end



-- BEGIN
function RoleService.begin()
	-- Create the hidden creator role
	-- This role is important as it ensures *the owner*
	-- of the game always has top priority
	local creatorRoleUID = DataUtil.generateUID(10)
	RoleService.createRole(false, {
		UID = creatorRoleUID,
		name = "Creator_"..creatorRoleUID,
		_order = 0,
		giveToCreator = true,
	})
end



-- METHODS
function RoleService.generateRecord()
	return {
		-- Appearance
		name = "Unnamed Role",
		color = Color3.fromRGB(255, 255, 255),
		nonadmin = false, -- This is solely for the 'nonadmins' and 'admins' qualifiers
		
		-- Role Givers
		giveToEveryone = false,
		giveToCreator = false,
		giveToUsers = {},
		giveToUsersWithGamepasses = {},
		giveToUsersWithAssets = {},
		giveToUsersOfRanksInGroups = {},
		giveToFriendsOfUsers = {},
		giveToVipServerOwner = false,
		giveToVipServerPlayers = false,
		giveToPremiumUsers = false,
		enableAccountAgeGiver = false,
		giveToUsersWithMinimumAccountAge = 0,
		enableDailyLoginStreakGiver = false,
		giveToUsersWithDailyLoginStreak = 14,
		giveToStarCreators = false,
		
		-- Command Inheritance
		inheritCommandsWithNames = {},
		inheritCommandsWithTags = {},
		inheritCommandsFromAllRoles = false,
		inheritCommandsFromJuniorRoles = true,
		inheritCommandsFromSpecificRoles = {},
		
		-- Limit Abuse
		limitCommandsPerInterval = true,
		commandRefreshInterval = 20,
		commandLimit = 20,
		limitGlobalExecutionsPerInterval = true,
		globalRefreshInterval = 20,
		globalLimit = 5,
		limitExecutions = false,
		executionCooldown = 1, -- if 'limitExecutions' is true, this amount of seconds must be waited before being allowed to execute another batch
		limitScale = true,
		scaleLimit = 5,
		limitBlacklistedIDs = true,
		limitToWhitelistedIDs = false, 
		
		-- Individual Powers
		canUseAll = false,
		canUseCommandsOnOthers = true,
		canUseCommandsOnFriends = true,
		canUseMultiQualifiers = true, -- Qualifiers which impact more than 1 person at a time (e.g. 'all', 'others'). This will also prevent multiple people being selected in a single execution
		canUseGlobalModifier = false,
		canUseLoopModifier = false,
		canUseCmdbar1 = false,
		canUseCmdbar2 = false,
		
		-- Client Prompts
		promptWelcomeRankNotice = true,
		
		-- Client Permissions & Pages
		canBlockAll = false,
		canBlockSeniors = false,
		canBlockPeers = false,
		canBlockJuniors = true,
		
		canViewAll = false,
		canEditAll = false,
		canEditGlobally = false,
		canViewUnusableCommands = true,
		canEditCommands = false,
		canViewRolesList = true,
		canEditRolesList = false,
		canViewServerRoles = true,
		canViewGlobalRoles = false,
		canEditGlobalRoles = false,
		canEditGlobalRolesBySeniors = false,
		canViewBans = false,
		canEditBans = false,
		canEditBansBySeniors = false,
		canViewWarnings = false,
		canEditWarnings = false,
		canEditWarningsBySeniors = false,
		canViewLogs = false,
		canEditLogs = false,
		canViewGlobalSettings = false,
		canEditGlobalSettings = false,
		
		-- Custom Chat
		-- https://devforum.roblox.com/t/bubblechats-epic-makeover/739458
		customBubble = false,
		bubbleImageColor = Color3.fromRGB(255, 255, 255),
		bubbleTextColor = Color3.fromRGB(255, 255, 255),
		bubbleTextFont = "SourceSans",
		customNameColor = false,
		nameColor = Color3.fromRGB(255, 255, 255),
		customChatColor = false,
		chatColor = Color3.fromRGB(255, 255, 255),
		customChatTags = false,
		chatTags = {
			{
				tagText = "",
				tagColor = Color3.fromRGB(255, 255, 255),
			}
		},
		
		-- Custom Title
		customTitle = false,
		titleText = "",
		titlePrimaryColor = Color3.fromRGB(255, 255, 255),
		titleStrokeColor = Color3.fromRGB(255, 255, 255),
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
	return role
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
		if role.name == name then
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
	RoleService:updateRecord(role.UID, propertiesToUpdate)
	return true
end

function RoleService.removeRole(nameOrUID)
	local role = RoleService.getRole(nameOrUID)
	assert(role, ("role '%s' not found!"):format(tostring(nameOrUID)))
	RoleService:removeRecord(role.UID)
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
		if role and (selectedRole == nil or approveRole(role._order, currentOrder)) then
			currentOrder, selectedRole = role._order, role
		end
	end
	if not selectedRole then
		selectedRole = {
			_order = 100,
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
	return roleA._order < roleB._order
end

function RoleService.isPeer(roleA, roleB)
	assert(typeof(roleA) == "table", "roleA must be a role or table!")
	assert(typeof(roleB) == "table", "roleB must be a role or table!")
	return roleA._order == roleB._order
end

function RoleService.isJunior(roleA, roleB)
	assert(typeof(roleA) == "table", "roleA must be a role or table!")
	assert(typeof(roleB) == "table", "roleB must be a role or table!")
	return roleA._order > roleB._order
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