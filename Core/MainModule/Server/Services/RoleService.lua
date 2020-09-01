-- LOCAL
local main = require(game.HDAdmin)
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
	warn(("ROLE '%s' ADDED!"):format(record.name))
	local role = Role.new(record)
	role.UID = roleUID
	roles[roleUID] = role
end)

RoleService.recordRemoved:Connect(function(roleUID)
	warn(("ROLE '%s' REMOVED!"):format(roleUID))
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
	warn(("ROLE '%s' CHANGED %s to %s (from %s)"):format(tostring(role and role.name), tostring(propertyName), tostring(propertyValue), tostring(propertyOldValue)))
end)



-- PLAYERSERVICE METHOD EVENTS
function RoleService.userLoadedMethod(user)
	-- Load user roles
	
	-- End
	user.isRolesLoaded = true
	user.rolesLoaded:Fire()
end



-- START
function RoleService:init()
	-- Create the hidden creator role
	-- This role is important as it ensures *the owner*
	-- of the game always has top priority
	local creatorRoleUID = DataUtil.generateUID(10)
	RoleService:createRole(false, {
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
		commandsLimit = 20, -- This includes *per person*
		limitGlobalExecutionsPerInterval = true,
		globalRefreshInterval = 20,
		globalsLimit = 5,
		limitScale = true,
		scaleLimit = 5,
		limitGear = true,
		limitQualifiers = false,
		permittedQualifiers = {},
		
		-- Individual Powers
		canUseAll = false,
		canUseGlobalModifier = false,
		canUseLoopModifier = false,
		canUseCmdbar1 = false,
		canUseCmdbar2 = false,
		
		-- Client Prompts
		promptWelcomeRankNotice = true,
		
		-- Client Permissions & Pages
		canBlockAll = false,
		canBlockPeers = false,
		canBlockJuniors = true,
		
		canViewAll = false,
		canEditAll = false,
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
		bubbleImageColor = Color3.fromRGB(),
		bubbleTextColor = Color3.fromRGB(),
		bubbleTextFont = "SourceSans",
		customNameColor = false,
		nameColor = Color3.fromRGB(),
		customChatColor = false,
		chatColor = Color3.fromRGB(),
		customChatTags = false,
		chatTags = {
			{
				tagText = "",
				tagColor = Color3.fromRGB(),
			}
		},
		
		-- Custom Title
		customTitle = false,
		titleText = "",
		titlePrimaryColor = Color3.fromRGB(),
		titleStrokeColor = Color3.fromRGB(),
	}
end

function RoleService.getHighestRole(tableOfRoles)
	-- Works for both arrays and dictionaries
	return {
		order = 0
	}
end

function RoleService:createRole(isGlobal, properties)
	-- The UID is a string to unqiquely identify each role
	-- We use this as the key instead of the roles name so that records
	-- can persist as the same instance even after being renamed
	local key = properties.UID or DataUtil.generateUID(10)
	RoleService:createRecord(key, isGlobal, properties)
	local role = RoleService:getRole(key)
	return role
end

function RoleService:getRole(nameOrUID)
	local role = RoleService:getRoleByUID(nameOrUID)
	if not role then
		role = RoleService:getRoleByName(nameOrUID)
	end
	return role
end

function RoleService:getRoleByUID(roleUID)
	local role = roles[roleUID]
	if not role then
		return false
	end
	return role
end

function RoleService:getRoleByName(name)
	for roleUID, role in pairs(roles) do
		if role.name == name then
			return role
		end
	end
	return false
end

function RoleService:getAllRoles()
	local allRoles = {}
	for name, role in pairs(roles) do
		table.insert(allRoles, role)
	end
	return allRoles
end

function RoleService:updateRole(nameOrUID, propertiesToUpdate)
	local role = RoleService:getRole(nameOrUID)
	assert(role, ("role '%s' not found!"):format(nameOrUID))
	RoleService:updateRecord(role.UID, propertiesToUpdate)
	return true
end

function RoleService:removeRole(nameOrUID)
	local role = RoleService:getRole(nameOrUID)
	assert(role, ("role '%s' not found!"):format(nameOrUID))
	RoleService:removeRecord(role.UID)
	return true
end



--[[
local main = require(game.HDAdmin)
local RoleService = main.services.RoleService
RoleService:createRole(true, {
	name = "Test server role"
})


local main = require(game.HDAdmin)
local RoleService = main.services.RoleService
local roleKey = "U0jS1tKiBf"
RoleService:removeRole(roleKey)


local main = require(game.HDAdmin)
local RoleService = main.services.RoleService
local roleKeyOrName = "Mod"
print(RoleService:getRole(roleKeyOrName))

--]]
return RoleService