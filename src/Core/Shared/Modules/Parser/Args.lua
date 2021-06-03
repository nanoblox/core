local main = require(game.Nanoblox)
local Args = {}



-- SETUP
if main.isServer then
	local argContainer = main.server:FindFirstChild("ArgResultContainer")
	if not argContainer then
		argContainer = Instance.new("Folder")
		argContainer.Name = "ArgResultStorage"
		argContainer.Parent = main.server
	end
	Args.argContainer = argContainer
	Args.storages = {}

	function Args.getStorage(storageName)
		local finalStorageName = storageName:sub(1,1):upper()..storageName:sub(2)
		local storageDetail = Args.storages[finalStorageName]
		if storageDetail then
			return storageDetail
		end
		local storageFolder = argContainer:FindFirstChild(finalStorageName)
		if not storageFolder then
			storageFolder = Instance.new("Folder")
			storageFolder.Name = finalStorageName
			storageFolder.Parent = argContainer
		end
		storageDetail = {
			items = {},
			folder = storageFolder,
			get = function(self, itemKey)
				local stringKey = tostring(itemKey)
				local item = self.items[stringKey]
				return item
			end,
			cache = function(self, itemKey, item)
				local stringKey = tostring(itemKey)
				self.items[stringKey] = item
				item.Name = stringKey
				if item.Parent ~= self.folder then
					item.Parent = self.folder
				end
			end
		}
		Args.storages[finalStorageName] = storageDetail
		for _, child in pairs(storageFolder:GetChildren()) do
			storageDetail:cache(child.Name, child)
		end
		return storageDetail
	end
end



-- ARRAY
Args.array = {

	-----------------------------------
	{
		name = "player",
		aliases = {},
		description = "Accepts qualifiers (e.g. 'raza', '@ForeverHD', 'others' from ';paint raza,@ForeverHD,others'), calls the command *for each player*, and returns a single Player instance.",
		playerArg = true,
		executeForEachPlayer = true,
		parse = function(self, qualifiers, callerUserId)
			local defaultToMe = qualifiers == nil or main.modules.TableUtil.isEmpty(qualifiers)
			if defaultToMe then
				local players = {}
				local callerPlayer = main.Players:GetPlayerByUserId(callerUserId)
				if callerPlayer then
					table.insert(players, callerPlayer)
				end
				return players
			end
			local targetsDict = {}
			for qualifierName, qualifierArgs in pairs(qualifiers or {}) do
				local Qualifiers = main.modules.Parser.Qualifiers
				local qualifierDetail = Qualifiers.get(qualifierName)
				local targets
				if not qualifierDetail then
					qualifierDetail = Qualifiers.get("user")
					targets = qualifierDetail.getTargets(callerUserId, qualifierName)
				else
					targets = qualifierDetail.getTargets(callerUserId, unpack(qualifierArgs))
				end
				for _, plr in pairs(targets) do
					targetsDict[plr] = true
				end
			end
			local players = {}
			for plr, _ in pairs(targetsDict) do
				table.insert(players, plr)
			end
			return players
		end,
	},

	-----------------------------------
	{
		name = "players",
		aliases = {},
		description = "Accepts qualifiers (e.g. 'raza', '@ForeverHD', 'others' from ';paint raza,@ForeverHD,others') and returns an array of Player instances.",
		playerArg = true,
		executeForEachPlayer = false,
		parse = function(self, qualifiers, callerUserId)
			return main.modules.Parser.Args.get("player"):parse(qualifiers, callerUserId)
		end,
	},

	-----------------------------------
	{
		name = "optionalplayer",
		aliases = {},
		description = "Hides the players argument for general use and only displays it within the preview menu.",
		playerArg = true,
		hidden = true,
		executeForEachPlayer = true,
		parse = function(self, qualifiers, callerUserId)
			local defaultToAll = qualifiers == nil or main.modules.TableUtil.isEmpty(qualifiers)
			if defaultToAll then
				return main.Players:GetPlayers()
			end
			return main.modules.Parser.Args.get("player"):parse(qualifiers, callerUserId)
		end,
	},

	-----------------------------------
	{
		name = "optionalplayers",
		aliases = {},
		description = "Hides the players argument for general use and only displays it within the preview menu.",
		playerArg = true,
		hidden = true,
		executeForEachPlayer = false,
		parse = function(self, qualifiers, callerUserId)
			return main.modules.Parser.Args.get("optionalplayer"):parse(qualifiers, callerUserId)
		end,
	},

	-----------------------------------
	{
		name = "text",
		aliases = {"string", "reason", "question", "teamname"},
		description = "Accepts a string and filters it based upon the caller and target.",
		defaultValue = "",
		parse = function(self, textToFilter, callerUserId, targetUserId)
			-- This is asynchronous
			local _, value = main.modules.ChatUtil.filterText(callerUserId, targetUserId, textToFilter):await()
			return value
		end,
	},

	-----------------------------------
	{
		name = "unfilteredtext",
		aliases = {"code", "lua"},
		description = "Accepts a string and returns it unfiltered.",
		defaultValue = "",
		parse = function(self, stringToParse)
			return stringToParse
		end,
	},

	-----------------------------------
	{
		name = "number",
		aliases = {"integer", "studs", "speed", "intensity"},
		description = "Accepts a number string and returns a Number",
		defaultValue = 0,
		parse = function(self, stringToParse)
			return tonumber(stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "sound",
		aliases = {"music", "audio"},
		displayName = "soundId",
		description = "Accepts a soundId (aka a LibraryId) and returns a Sound instance if valid. Do not use the returned Sound instance, clone it instead.",
		defaultValue = false,
		parse = function(self, stringToParse)
			local storageDetail = Args.getStorage(self.name)
			local cachedItem = storageDetail:get(stringToParse)
			if cachedItem then
				return cachedItem
			end
			local newSound = Instance.new("Sound")
			newSound.SoundId = "rbxassetid://"..stringToParse
			storageDetail:cache(stringToParse, newSound)
			return newSound
		end,
		verifyCanUse = function(self, callerUser, stringToParse)
			-- Check if valid string
			local soundIdString = string.match(stringToParse, "%d+")
			local soundId = tonumber(soundIdString)
			if not soundId then
				return false, string.format("'%s' is an invalid ID!", stringToParse)
			end
			-- Check if restricted to user
			local approved, warning = main.services.SettingService.verifyCanUseRestrictedID(callerUser, "library", soundIdString)
			if not approved then
				return false, warning
			end
			-- Check if correct asset type
			local assetType = main.modules.ProductUtil.getAssetTypeAsync(soundId, Enum.InfoType.Asset)
			if assetType ~= Enum.AssetType.Audio.Value then
				return false, string.format("'%s' is not a valid SoundID!", soundId)
			end
			return true
		end,
	},

	-----------------------------------
	{
		name = "gear", -- Consider gear limits
		aliases = {},
		displayName = "gearId",
		description = "Accepts a gearId (aka a CatalogId) and returns the Tool instance if valid. Do not use the returned Tool instance, clone it instead.",
		defaultValue = false,
		parse = function(self, stringToParse)
			local storageDetail = Args.getStorage(self.name)
			local cachedItem = storageDetail:get(stringToParse)
			if cachedItem then
				return cachedItem
			end
			local success, model = pcall(function() return(main.InsertService:LoadAsset(stringToParse)) end)
			if not success then
				return
			end
			local tool = model:FindFirstChildOfClass("Tool")
			if tool then
				storageDetail:cache(stringToParse, tool)
			end
			model:Destroy()
			return tool
		end,
		verifyCanUse = function(self, callerUser, stringToParse)
			-- Check if valid string
			local gearIdString = string.match(stringToParse, "%d+")
			local gearId = tonumber(gearIdString)
			if not gearId then
				return false, string.format("'%s' is an invalid ID!", stringToParse)
			end
			-- Check if restricted to user
			local approved, warning = main.services.SettingService.verifyCanUseRestrictedID(callerUser, "catalog", gearIdString)
			if not approved then
				return false, warning
			end
			-- Check if correct asset type
			local assetType = main.modules.ProductUtil.getAssetTypeAsync(gearId, Enum.InfoType.Asset)
			if assetType ~= Enum.AssetType.Gear.Value then
				return false, string.format("'%s' is not a valid GearID!", gearId)
			end
			return true
		end,
	},

	-----------------------------------
	{
		name = "scale", -- Consider scale limits
		aliases = {},
		description = "Accepts a number and returns a number which is considerate of scale limits.",
		defaultValue = 1,
		parse = function(self, stringToParse)
			--[[
			argToProcess = tonumber(argToProcess) or 1
			local scaleLimit = main.settings.ScaleLimit
			local ignoreRank = main.settings.IgnoreScaleLimit
			if argToProcess > scaleLimit and speakerData.Rank < ignoreRank then
				local rankName = main:GetModule("cf"):GetRankName(ignoreRank)
				main:GetModule("cf"):FormatAndFireError(speaker, "ScaleLimit", scaleLimit, rankName)
				forceExit = true
			elseif argToProcess > 50 then
				argToProcess = 100
			end
			]]
		end,
		verifyCanUse = function(self, callerUser, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "duration", -- returns the time string (such as 5s7d8h) in seconds
		aliases = {"time", "durationtime", "timelength"},
		description = "Accepts a timestring (such as '5s7d8h') and returns the integer equivalent in seconds. Timestring letters are: seconds(s), minutes(m), hours(h), days(d), weeks(w), months(o) and years(y).",
		defaultValue = 0,
		parse = function(self, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "degrees",
		aliases = {},
		description = "Accepts a number and returns a value between 0 and 360.",
		defaultValue = 0,
		parse = function(self, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "role",
		aliases = {},
		displayName = "roleName",
		description = "Accepts a valid role name and returns the role object.",
		defaultValue = false,
		parse = function(self, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "color", -- have a predefined list of colors such as 'red', 'blue', etc which the user can reference. also consider rgb capsules
		aliases = {"colour", "color3", "uigradient", "colorgradient", "gradient"},
		description = "Accepts a color name (such as 'red'), a hex code (such as '#FF0000') or an RGB capsule (such as '[255,0,0]') and returns a Color3.",
		defaultValue = Color3.fromRGB(255, 255, 255),
		parse = function(self, stringToParse)
			-- predifined terms like 'blue', 'red', etc
			-- RGB codes such as '100,110,120'
			-- hex codes such as #FF5733
			return stringToParse
			--return Color3.fromRGB(50, 100, 150)
		end,
	},

	-----------------------------------
	{
		name = "optionalcolor",
		aliases = {"optionalcolour", "optionalcolor3"},
		description = "Accepts a color name (such as 'red'), a hex code (such as '#FF0000') or an RGB capsule (such as '[255,0,0]') and returns a Color3.",
		defaultValue = Color3.fromRGB(255, 255, 255),
		hidden = true,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "bool",
		aliases = {"boolean", "trueOrFalse", "yesOrNo"},
		description = "Accepts 'true', 'false', 'yes' or 'no' and returns a boolean.",
		defaultValue = false,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "stat", -- Consider making a setting to update this or set its pathway
		aliases = {"statName"},
		description = "Accepts a valid stat name and returns the stat.",
		defaultValue = false,
		parse = function(self, stringToParse)
			-- maybe this should also be a statName
		end,
	},

	-----------------------------------
	{
		name = "userid",
		aliases = {},
		displayName = "userNameOrId",
		description = "Accepts an @userName, displayName or userId and returns a userId.",
		defaultValue = 0,
		parse = function(self, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "username", -- returns a string instead of a player instance - it fist looks for a player in the server otherwise defaults to the given string
		aliases = {"playerOrUser"},
		displayName = "userNameOrId",
		description = "Accepts an @userName, displayName or userId and returns a username. It first checks the players of that server for a matching shorthand name and returns their userName if present.",
		defaultValue = "",
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "team",
		displayName = "teamName",
		aliases = {},
		description = "Accepts a valid team name and returns the team instance.",
		defaultValue = false,
		parse = function(self, stringToParse)
			local stringToParseLower = string.lower(stringToParse)
			for _,team in pairs(main.Teams:GetChildren()) do
				local teamName = string.lower(team.Name)
				if string.sub(teamName, 1, #stringToParseLower) == stringToParseLower then
					return team
				end
			end
		end,
	},

	-----------------------------------
	{
		name = "teamcolor",
		displayName = "teamName",
		aliases = {},
		description = "Accepts a valid team name and returns the teams TeamColor.",
		defaultValue = false,
		parse = function(self, stringToParse)
			local stringToParseLower = string.lower(stringToParse)
			for _,team in pairs(main.Teams:GetChildren()) do
				local teamName = string.lower(team.Name)
				if string.sub(teamName, 1, #stringToParseLower) == stringToParseLower then
					return team.TeamColor
				end
			end
		end,
	},

	-----------------------------------
	{
		name = "material",
		aliases = {},
		description = "Accepts a valid material and returns a Material enum.",
		defaultValue = Enum.Material.Plastic,
		parse = function(self, stringToParse)
			local enumName = stringToParse:sub(1,1):upper()..stringToParse:sub(2):lower()
			local success, enum = pcall(function() return Enum.Material[enumName] end)
			return (success and enum)
		end,
	},

	-----------------------------------
	{
		name = "tool",
		aliases = {"item"},
		displayName = "toolName",
		description = "Accepts a tool name that was present in either Nanoblox/Extensions/Tools, ServerStorage, ReplicatedStorage or Workspace upon the server initialising and returns the Tool instance",
		defaultValue = false,
		parse = function(self, stringToParse)
			-- consider searching workspace, serverscriptservice, nanoblox, etc for that tool
		end,
	},

	-----------------------------------
	{
		name = "morph",
		aliases = {},
		displayName = "morphName",
		description = "Accepts a valid morph name and returns the morph",
		defaultValue = false,
		parse = function(self, stringToParse)

		end,
	},

	-----------------------------------
}

-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Args.dictionary.ARGUMENT_NAME`` to return its item
Args.dictionary = {}
Args.lowerCaseNameAndAliasToArgDictionary = {}
for _, item in pairs(Args.array) do
	Args.dictionary[item.name] = item
	Args.lowerCaseNameAndAliasToArgDictionary[item.name:lower()] = item
	for _, alias in pairs(item.aliases) do
		Args.dictionary[alias] = item
		Args.lowerCaseNameAndAliasToArgDictionary[alias:lower()] = item
	end
end

-- SORTED ARRAY(S)
Args.executeForEachPlayerArgsDictionary = {}
for _, item in pairs(Args.array) do
	if item.playerArg and item.executeForEachPlayer then
		Args.executeForEachPlayerArgsDictionary[item.name:lower()] = true
	end
end

-- METHODS
function Args.get(name)
	return Args.lowerCaseNameAndAliasToArgDictionary[name:lower()]
end

return Args
