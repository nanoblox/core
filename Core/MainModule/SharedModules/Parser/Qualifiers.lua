-- LOCAL
local main = require(game.HDAdmin)
local Qualifiers = {}
local function isNonadmin(user)
	local totalNonadmins = 0
	local totalRoles = 0
	for roleUID, roleDetails in pairs(user.roles) do
		local role = main.services.RoleService:getRoleByUID(roleUID)
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
		names = {"users", "user"},
		hidden = true,
		description	= "Default action, returns players with matching shorthand names.",
		getTargets = function(caller, shorthandString)
			local targets = {}
			for i, plr in pairs(main.Players:GetPlayers()) do
				local plrName = string.lower(plr.Name)
				if string.sub(plrName, 1, #shorthandString) == shorthandString then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"me", "you"},
		description	= "You!",
		getTargets = function(caller)
			return {caller.player}
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"all", "everyone"},
		description	= "Every player in a server.",
		getTargets = function(caller)
			return main.Players:GetPlayers()
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"random"},
		description	= "One randomly selected player from a pool. To define a pool, do ``random(qualifier1,qualifier2,...)``. If not defined, the pool defaults to 'all'.",
		getTargets = function(caller, ...)
			local subQualifiers = table.pack(...)
			if #subQualifiers == 0 then
				table.insert(subQualifiers, "all")
			end
			local pool = {}
			for _, subQualifier in pairs(subQualifiers) do
				local subPool = ((Qualifiers.dictionary[subQualifier] or Qualifiers.defaultQualifier).getTargets(caller)) or {}
				for _, plr in pairs(subPool) do
					table.insert(pool, plr)
				end
			end
			local targets = {pool[math.random(1, #pool)]}
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"others"},
		description	= "Every player in a server except you.",
		getTargets = function(caller)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				if plr.Name ~= caller.name then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"radius"},
		description	= "Players within x amount of studs from you. To specify studs, do ``radius(studs)``. If not defined, studs defaults to '10'.",
		getTargets = function(caller, radiusString)
			local targets = {}
			local radius = tonumber(radiusString) or 10
			local callerHeadPos = main.modules.PlayerUtil.getHeadPos(caller.player) or Vector3.new(0, 0, 0)
			for _, plr in pairs(main.Players:GetPlayers()) do
				if plr:DistanceFromCharacter(callerHeadPos) <= radius then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"team", "teams", "$"},
		description	= "Players within the specified team(s).",
		getTargets = function(caller, ...)
			local targets = {}
			local teamNames = table.pack(...)
			local selectedTeams = {}
			local validTeams = false
			if #teamNames == 0 then return {} end
			for _,team in pairs(main.Teams:GetChildren()) do
				local teamName = string.lower(team.Name)
				for _, selectedTeamName in pairs(teamNames) do
					if string.sub(teamName, 1, #selectedTeamName) == selectedTeamName then
						selectedTeams[tostring(team.TeamColor)] = true
						validTeams = true
					end
				end
			end
			if not validTeams then return {} end
			for i, plr in pairs(main.Players:GetPlayers()) do
				if selectedTeams[tostring(plr.TeamColor)] then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"role", "roles", "@"},
		description	= "Players who have the specified role(s).",
		getTargets = function(caller, ...)
			local targets = {}
			local roleNames = table.pack(...)
			local selectedRoleUIDs = {}
			if #roleNames == 0 then return {} end
			for _, role in pairs(main.services.RoleService:getAllRoles()) do
				local roleName = string.lower(role.name)
				local roleUID = role.UID
				for _, selectedRoleName in pairs(roleNames) do
					if string.sub(roleName, 1, #selectedRoleName) == selectedRoleName or roleUID == selectedRoleName then
						table.insert(selectedRoleUIDs, roleUID)
					end
				end
			end
			if #selectedRoleUIDs == 0 then return {} end
			for i, user in pairs(main.modules.PlayerStore:getAllUsers()) do
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
	};
	
	
	
	-----------------------------------
	{
		names = {"percent", "percentage", "%"},
		description	= "Randomly selects x percent of players within a server. To define the percentage, do ``percent(number)``. If not defined, the percent defaults to '50'.",
		getTargets = function(caller, percentString)
			local targets = {}
			local maxPercent = tonumber(percentString) or 50
			local players = main.Players:GetPlayers()
			local interval = 100/#players
			if maxPercent >= (100-(interval*0.1)) then
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
	};
	
	
	
	-----------------------------------
	{
		names = {"admins"},
		description	= "Selects all admins",
		getTargets = function(caller)
			local targets = {}
			for i, user in pairs(main.modules.PlayerStore:getAllUsers()) do
				if not isNonadmin(user) then
					table.insert(targets, user.player)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"nonadmins"},
		description	= "Selects all nonadmins",
		getTargets = function(caller)
			local targets = {}
			for i, user in pairs(main.modules.PlayerStore:getAllUsers()) do
				if isNonadmin(user) then
					table.insert(targets, user.player)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"premium", "prem"},
		description	= "Players with Roblox Premium membership",
		getTargets = function(caller)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				if plr.MembershipType == Enum.MembershipType.Premium then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"friends"},
		description	= "Players you are friends with",
		getTargets = function(caller)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				if caller.player:IsFriendsWith(plr.UserId) then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"nonfriends"},
		description	= "Players you are not friends with",
		getTargets = function(caller)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				if not caller.player:IsFriendsWith(plr.UserId) and caller.player ~= plr.UserId then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"r6"},
		description	= "Players with an R6 character rig",
		getTargets = function(caller)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				local humanoid = main.modules.PlayerUtil.getHumanoid(plr)
				if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"r15"},
		description	= "Players with an R15 character rig",
		getTargets = function(caller)
			local targets = {}
			for _, plr in pairs(main.Players:GetPlayers()) do
				local humanoid = main.modules.PlayerUtil.getHumanoid(plr)
				if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
					table.insert(targets, plr)
				end
			end
			return targets
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"rthro"},
		description	= "Players with a Body Type value greater than or equal to 90%",
		getTargets = function(caller)
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
	};
	
	
	
	-----------------------------------
	{
		names = {"nonrthro"},
		description	= "Players with a Body Type value less than 90%",
		getTargets = function(caller)
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
	};
	
	
	
	-----------------------------------
	
};



-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Qualifiers.dictionary.QUALIFIER_NAME`` to return its details
Qualifiers.dictionary = {}
for _, details in pairs(Qualifiers.array) do
	for _, name in pairs(details.names) do
		Qualifiers.dictionary[name] = details
	end
end



-- OTHER
Qualifiers.defaultQualifier = Qualifiers.dictionary["user"]



return Qualifiers