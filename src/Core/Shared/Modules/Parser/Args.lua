local main = require(game.Nanoblox)
local Args = {}

-- ARRAY
Args.array = {

	-----------------------------------
	{
		name = "player",
		aliases = {},
		description = "",
		defaultValue = 0,
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
			local targetsDict = {} -- IF THIS IS COMPLETELY EMPTY THEN DEFAULY TO 'ME' BUT CONSIDER HOW IT IMPACTS OTHER PLAYERS ONES
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
		description = "",
		defaultValue = 0,
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
		defaultValue = 0,
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
		defaultValue = 0,
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
		aliases = { "string", "reason", "question", "teamname" },
		description = "",
		defaultValue = 0,
		parse = function(self, textToFilter, callerUserId, targetUserId)
			-- This is asynchronous
			local _, value = main.modules.ChatUtil.filterText(callerUserId, targetUserId, textToFilter):await()
			return value
		end,
	},

	-----------------------------------
	{
		name = "code",
		aliases = { "lua" },
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			return stringToParse
		end,
	},

	-----------------------------------
	{
		name = "number",
		aliases = { "integer", "studs", "speed", "intensity" },
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			return tonumber(stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "soundid", -- consider blocking soundids and a setting to achieve this
		aliases = { "musicid" },
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "scale", -- Consider scale limits
		aliases = {},
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)

		end,
	},

	-----------------------------------
	{
		name = "gearId", -- Consider gear limits
		aliases = {},
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	},

	-----------------------------------
	{
		name = "duration", -- returns the time string (such as 5s7d8h) in seconds
		aliases = { "time", "durationtime", "timelength" },
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "degrees",
		aliases = {},
		description = "",
		defaultValue = 180,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "role",
		aliases = {},
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "color", -- have a predefined list of colors such as 'red', 'blue', etc which the user can reference. also consider rgb capsules
		aliases = { "colour", "color3", "uigradient", "colorgradient", "gradient" },
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			-- predifined terms like 'blue', 'red', etc
			-- RGB codes such as '100,110,120'
			-- hex codes such as #FF5733
			return Color3.fromRGB(50, 100, 150)
		end,
	},

	-----------------------------------
	{
		name = "optionalcolor",
		aliases = { "optionalcolour", "optionalcolor3" },
		description = "",
		defaultValue = 0,
		hidden = true,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "bool",
		aliases = { "boolean", "trueOrFalse", "yesOrNo" },
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "stat", -- Consider making a setting to update this or set its pathway
		aliases = { "statName" },
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "user",
		aliases = { "username", "userid", "playerid", "playername" },
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "playeroruser", -- returns a string instead of a player instance - it fist looks for a player in the server otherwise defaults to the given string
		aliases = {},
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "team",
		aliases = {},
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "teamcolor",
		aliases = {},
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "material",
		aliases = {},
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "tool",
		aliases = { "gear", "item" },
		description = "",
		defaultValue = 0,
		parse = function(self, stringToParse)
		end,
	},

	-----------------------------------
	{
		name = "morph",
		aliases = {},
		description = "",
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
