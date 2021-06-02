local main = require(game.Nanoblox)
local Args = {}

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
			return nil
			--return tonumber(stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "sound", -- consider blocking soundids and a setting to achieve this
		aliases = {"music"},
		description = "Accepts a soundId (aka a LibraryId) and returns the Sound instance if valid.",
		defaultValue = 0,
		parse = function(self, stringToParse)
			-- cache the sound item, and return the sound item
			return stringToParse
			-- verify is a sound, and the sound can play
		end,
		verifyCanUse = function(self, callerUser, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "scale", -- Consider scale limits
		aliases = {},
		description = "Accepts a number and returns a number which is considerate of scale limits.",
		defaultValue = 1,
		parse = function(self, stringToParse)

		end,
		verifyCanUse = function(self, callerUser, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "gear", -- Consider gear limits
		aliases = {},
		displayName = "gearId",
		description = "Accepts a gearId (aka a CatalogId) and returns the Tool instance if valid.",
		defaultValue = 0,
		parse = function(self, stringToParse)
			-- cache the gear item, and return the gear item
			-- very asset type is a gear
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
		defaultValue = "",
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
		defaultValue = "",
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
		defaultValue = "",
		parse = function(self, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "username", -- returns a string instead of a player instance - it fist looks for a player in the server otherwise defaults to the given string
		aliases = {"playerOrUser"},
		displayName = "userNameOrId",
		description = "Accepts an @userName, displayName or userId and returns a username. It first checks the players of that server for a matching shorthand name and returns their userName if present.",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "team",
		displayName = "teamName",
		aliases = {},
		description = "Accepts a valid team name and returns the team instance.",
		defaultValue = 0,
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
		defaultValue = 0,
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
		aliases = {"gear", "item"},
		displayName = "toolName",
		description = "Accepts a tool name that was present in either Nanoblox/Extensions/Tools, ServerStorage, ReplicatedStorage or Workspace upon the server initialising and returns the Tool instance",
		defaultValue = 0,
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
		defaultValue = 0,
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
