-- LOCAL
local main = require(game.Nanoblox)
local Qualifiers = {}
local function isNonadmin(user)
	local totalNonadmins = 0
	local totalRoles = 0
	for roleUID, roleDetails in pairs(user.roles) do
		local role = main.services.RoleService.getRoleByUID(roleUID)
		if role.nonadmin == true then
			totalNonadmins = totalNonadmins + 1
		end
		totalRoles = totalRoles + 1
	end
end

-- ARRAY
Qualifiers.array = {

	-----------------------------------
	{
		name = "user",
		aliases = { "users" },
		hidden = true,
		multi = false,
		description	= "Default action, returns players with matching shorthand names.",
		getTargets = function(callerUserId, shorthandString, useDisplayName)
			local targets = {}
			for i, plr in pairs(main.Players:GetPlayers()) do
				local nameToUse = (useDisplayName and plr.DisplayName) or plr.Name
				local plrName = nameToUse:lower()
				if string.sub(plrName, 1, #shorthandString) == shorthandString:lower() then
					table.insert(targets, plr)
				end
			end
			--!!! IF CALLER HAS MULTI DISABLED, ONLY RETURN 1 (this is a setting I believe in roles)
			if callerUserId and callerUserCanOnlyUseOnOne and #targets > 1 then
				return {targets[1]}
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "me",
		aliases = { "you" },
		multi = false,
		description = "You!",
		getTargets = function(callerUserId)
			local targets = {}
			local caller = main.Players:GetPlayerByUserId(callerUserId)
			if caller then
				table.insert(targets, caller)
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "all",
		aliases = { "everyone" },
		multi = true,
		description = "Every player in a server.",
		getTargets = function()
			return main.Players:GetPlayers()
		end,
	},

	-----------------------------------
	{
		name = "random",
		aliases = {},
		multi = false,
		description = "One randomly selected player from a pool. To define a pool, do ``random(qualifier1,qualifier2,...)``. If not defined, the pool defaults to 'all'.",
		getTargets = function(callerUserId, ...)
			local subQualifiers = table.pack(...)
			if #subQualifiers == 0 then
				table.insert(subQualifiers, "all")
			end
			local pool = {}
			for _, subQualifier in pairs(subQualifiers) do
				local subPool = ((Qualifiers.get(subQualifier) or Qualifiers.defaultQualifier).getTargets(callerUserId))
					or {}
				for _, plr in pairs(subPool) do
					table.insert(pool, plr)
				end
			end
			local targets = { pool[math.random(1, #pool)] }
			return targets
		end,
	},

	-----------------------------------
	{
		name = "others",
		aliases = { "other" },
		multi = true,
		description = "Every player in a server except you.",
		getTargets = function(callerUserId)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				if plr.UserId ~= callerUserId then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "radius",
		aliases = {},
		multi = true,
		description = "Players within x amount of studs from you. To specify studs, do ``radius(studs)``. If not defined, studs defaults to '10'.",
		getTargets = function(callerUserId, radiusString)
			local targets = {}
			local radius = tonumber(radiusString) or 10
			local caller = main.Players:GetPlayerByUserId(callerUserId)
			if caller then
				local callerHeadPos = main.modules.PlayerUtil.getHeadPos(caller.player) or Vector3.new(0, 0, 0)
				for _, plr in pairs(main.Players:GetPlayers()) do
					if plr:DistanceFromCharacter(callerHeadPos) <= radius then
						table.insert(targets, plr)
					end
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "team",
		aliases = { "teams", "$" },
		multi = true,
		description = "Players within the specified team(s).",
		getTargets = function(_, ...)
			local targets = {}
			local teamNames = table.pack(...)
			local selectedTeams = {}
			local validTeams = false
			if #teamNames == 0 then
				return {}
			end
			for _, team in pairs(main.Teams:GetChildren()) do
				local teamName = string.lower(team.Name)
				for _, selectedTeamName in pairs(teamNames) do
					if string.sub(teamName, 1, #selectedTeamName) == selectedTeamName then
						selectedTeams[tostring(team.TeamColor)] = true
						validTeams = true
					end
				end
			end
			if not validTeams then
				return {}
			end
			for i, plr in pairs(main.Players:GetPlayers()) do
				if selectedTeams[tostring(plr.TeamColor)] then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "group",
		aliases = {"groups"},
		multi = true,
		description	= "Players who are in the specified group(s).",
		getTargets = function(_, ...)
			local targets = {}
			local groupIds = {}
			for _, groupId in pairs(table.pack(...)) do
				groupId = tonumber(groupId)
				if groupId then
					table.insert(groupIds, groupId)
				end
			end
			for _, plr in pairs(main.Players:GetPlayers()) do
				for _, groupId in pairs(groupIds) do
					if plr:IsInGroup(groupId) then
						table.insert(targets, plr)
						break
					end
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "role",
		aliases = { "roles", "@" },
		multi = true,
		description = "Players who have the specified role(s).",
		getTargets = function(_, ...)
			local targets = {}
			local roleNames = table.pack(...)
			local selectedRoleUIDs = {}
			if #roleNames == 0 then
				return {}
			end
			for _, role in pairs(main.services.RoleService.getRoles()) do
				local roleName = string.lower(role.name)
				local roleUID = role.UID
				for _, selectedRoleName in pairs(roleNames) do
					if
						string.sub(roleName, 1, #selectedRoleName) == selectedRoleName
						or roleUID == selectedRoleName
					then
						table.insert(selectedRoleUIDs, roleUID)
					end
				end
			end
			if #selectedRoleUIDs == 0 then
				return {}
			end
			for i, user in pairs(main.modules.PlayerStore:getUsers()) do
				local function isValidUser()
					for _, roleUID in pairs(selectedRoleUIDs) do
						if user.roles[roleUID] then
							return true
						end
					end
					return false
				end
				if isValidUser() then
					table.insert(targets, user.player)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "percent",
		aliases = { "percentage", "%" },
		multi = true,
		description = "Randomly selects x percent of players within a server. To define the percentage, do ``percent(number)``. If not defined, the percent defaults to '50'.",
		getTargets = function(_, percentString)
			local targets = {}
			local maxPercent = tonumber(percentString) or 50
			local players = main.Players:GetPlayers()
			local interval = 100 / #players
			if maxPercent >= (100 - (interval * 0.1)) then
				return players
			end
			local selectedPercent = 0
			repeat
				local randomIndex = math.random(1, #players)
				local selectedPlayer = players[randomIndex]
				table.insert(targets, selectedPlayer)
				table.remove(players, randomIndex)
			until #players == 0 or selectedPercent >= maxPercent
			return targets
		end,
	},

	-----------------------------------
	{
		name = "admins",
		aliases = {},
		multi = true,
		description = "Selects all admins",
		getTargets = function(_)
			local targets = {}
			for i, user in pairs(main.modules.PlayerStore:getUsers()) do
				if not isNonadmin(user) then
					table.insert(targets, user.player)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "nonadmins",
		aliases = {},
		multi = true,
		description = "Selects all nonadmins",
		getTargets = function(_)
			local targets = {}
			for i, user in pairs(main.modules.PlayerStore:getUsers()) do
				if isNonadmin(user) then
					table.insert(targets, user.player)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "premium",
		aliases = { "prem" },
		multi = true,
		description = "Players with Roblox Premium membership",
		getTargets = function(_)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				if plr.MembershipType == Enum.MembershipType.Premium then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "nonpremium",
		aliases = { "nonprem" },
		multi = true,
		description = "Players without Roblox Premium membership",
		getTargets = function(_)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				if plr.MembershipType == Enum.MembershipType.None then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "friends",
		aliases = {},
		multi = true,
		description = "Players you are friends with",
		getTargets = function(callerUserId)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				if plr:IsFriendsWith(callerUserId) then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "nonfriends",
		aliases = {},
		multi = true,
		description = "Players you are not friends with",
		getTargets = function(callerUserId)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				if not plr:IsFriendsWith(callerUserId) and callerUserId ~= plr.UserId then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "r6",
		aliases = {},
		multi = true,
		description = "Players with an R6 character rig",
		getTargets = function()
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				local humanoid = main.modules.PlayerUtil.getHumanoid(plr)
				if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "r15",
		aliases = {},
		multi = true,
		description = "Players with an R15 character rig",
		getTargets = function()
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				local humanoid = main.modules.PlayerUtil.getHumanoid(plr)
				if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "rthro",
		aliases = {},
		multi = true,
		description = "Players with a Body Type value greater than or equal to 90%",
		getTargets = function()
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				local humanoid = main.modules.PlayerUtil.getHumanoid(plr)
				local bts = humanoid and humanoid:FindFirstChild("BodyTypeScale")
				if bts and bts.Value >= 0.9 then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
	{
		name = "nonrthro",
		aliases = {},
		multi = true,
		description = "Players with a Body Type value less than 90%",
		getTargets = function()
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				local humanoid = main.modules.PlayerUtil.getHumanoid(plr)
				local bts = humanoid and humanoid:FindFirstChild("BodyTypeScale")
				if not bts or bts.Value < 0.9 then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	},

	-----------------------------------
}

-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Qualifiers.dictionary.QUALIFIER_NAME`` to return its item
Qualifiers.dictionary = {}
Qualifiers.lowerCaseNameAndAliasToArgDictionary = {}
for _, item in pairs(Qualifiers.array) do
	Qualifiers.dictionary[item.name] = item
	Qualifiers.lowerCaseNameAndAliasToArgDictionary[item.name:lower()] = item
	for _, alias in pairs(item.aliases) do
		Qualifiers.dictionary[alias] = item
		Qualifiers.lowerCaseNameAndAliasToArgDictionary[alias:lower()] = item
	end
end

-- SORTED ARRAY(S)
local copy = main.modules.TableUtil.copy
Qualifiers.sortedNameAndAliasLengthArray = {}
for itemNameOrAlias, item in pairs(Qualifiers.dictionary) do
	table.insert(Qualifiers.sortedNameAndAliasLengthArray, itemNameOrAlias)
end
table.sort(Qualifiers.sortedNameAndAliasLengthArray, function(a, b)
	return #a > #b
end)

-- OTHER
Qualifiers.defaultQualifier = Qualifiers.dictionary["user"]

-- METHODS
function Qualifiers.get(name)
	return Qualifiers.lowerCaseNameAndAliasToArgDictionary[name:lower()]
end



return Qualifiers
